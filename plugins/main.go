package main

import (
	"C"
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"
	"unsafe"

	"github.com/eiannone/keyboard"
	_ "github.com/mattn/go-sqlite3"
)

var keyNames = map[keyboard.Key]string{
	keyboard.KeyF1:         "F1",
	keyboard.KeyF2:         "F2",
	keyboard.KeyF3:         "F3",
	keyboard.KeyF4:         "F4",
	keyboard.KeyF5:         "F5",
	keyboard.KeyF6:         "F6",
	keyboard.KeyF7:         "F7",
	keyboard.KeyF8:         "F8",
	keyboard.KeyF9:         "F9",
	keyboard.KeyF10:        "F10",
	keyboard.KeyF11:        "F11",
	keyboard.KeyF12:        "F12",
	keyboard.KeyInsert:     "Insert",
	keyboard.KeyDelete:     "Delete",
	keyboard.KeyHome:       "Home",
	keyboard.KeyEnd:        "End",
	keyboard.KeyPgup:       "PageUp",
	keyboard.KeyPgdn:       "PageDown",
	keyboard.KeyArrowUp:    "ArrowUp",
	keyboard.KeyArrowDown:  "ArrowDown",
	keyboard.KeyArrowLeft:  "ArrowLeft",
	keyboard.KeyArrowRight: "ArrowRight",
	keyboard.KeyBackspace:  "Backspace",
	keyboard.KeyTab:        "Tab",
	keyboard.KeyEnter:      "Enter",
	keyboard.KeyEsc:        "Esc",
	keyboard.KeySpace:      "Space",
	keyboard.KeyCtrlSpace:  "Ctrl+Space",
	keyboard.KeyCtrlA:      "Ctrl+A",
	keyboard.KeyCtrlB:      "Ctrl+B",
	keyboard.KeyCtrlC:      "Ctrl+C",
	keyboard.KeyCtrlD:      "Ctrl+D",
	keyboard.KeyCtrlE:      "Ctrl+E",
	keyboard.KeyCtrlF:      "Ctrl+F",
	keyboard.KeyCtrlG:      "Ctrl+G",
	keyboard.KeyCtrlJ:      "Ctrl+J",
	keyboard.KeyCtrlK:      "Ctrl+K",
	keyboard.KeyCtrlL:      "Ctrl+L",
	keyboard.KeyCtrlN:      "Ctrl+N",
	keyboard.KeyCtrlO:      "Ctrl+O",
	keyboard.KeyCtrlP:      "Ctrl+P",
	keyboard.KeyCtrlQ:      "Ctrl+Q",
	keyboard.KeyCtrlR:      "Ctrl+R",
	keyboard.KeyCtrlS:      "Ctrl+S",
	keyboard.KeyCtrlT:      "Ctrl+T",
	keyboard.KeyCtrlU:      "Ctrl+U",
	keyboard.KeyCtrlV:      "Ctrl+V",
	keyboard.KeyCtrlW:      "Ctrl+W",
	keyboard.KeyCtrlX:      "Ctrl+X",
	keyboard.KeyCtrlY:      "Ctrl+Y",
	keyboard.KeyCtrlZ:      "Ctrl+Z",
}

var (
	db            *sql.DB
	callback      func(key uint16, timestamp int64)
	callbackMutex sync.RWMutex
	isListening   bool
	stopListening chan bool
)

//export InitDatabase
func InitDatabase(dbPath *C.char) *C.char {
	path := C.GoString(dbPath)
	var err error
	db, err = sql.Open("sqlite3", path)
	if err != nil {
		return C.CString(fmt.Sprintf("Error opening database: %v", err))
	}

	createTableSQL := `CREATE TABLE IF NOT EXISTS keystrokes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		key_code INTEGER NOT NULL,
		key_name TEXT,
		timestamp INTEGER NOT NULL,
		date TEXT NOT NULL,
		hour INTEGER NOT NULL
	);`

	_, err = db.Exec(createTableSQL)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating table: %v", err))
	}

	createIndexSQL := `CREATE INDEX IF NOT EXISTS idx_date ON keystrokes(date);
	CREATE INDEX IF NOT EXISTS idx_hour ON keystrokes(hour);`
	_, err = db.Exec(createIndexSQL)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating index: %v", err))
	}

	return C.CString("")
}

//export SetKeyCallback
func SetKeyCallback(fn unsafe.Pointer) {
	callbackMutex.Lock()
	defer callbackMutex.Unlock()
	callback = *(*func(uint16, int64))(fn)
}

//export StartListening
func StartListening() *C.char {
	if isListening {
		return C.CString("Already listening")
	}

	if db == nil {
		return C.CString("Database not initialized")
	}

	err := keyboard.Open()
	if err != nil {
		return C.CString(fmt.Sprintf("Error opening keyboard: %v", err))
	}

	isListening = true
	stopListening = make(chan bool)

	go func() {
		defer keyboard.Close()
		for {
			select {
			case <-stopListening:
				return
			default:
				char, key, err := keyboard.GetKey()
				if err != nil {
					log.Printf("Error reading key: %v", err)
					continue
				}

				now := time.Now()
				timestamp := now.UnixMilli()
				date := now.Format("2006-01-02")
				hour := now.Hour()

				var keyCode uint16
				var keyName string

				if char != 0 {
					keyCode = uint16(char)
					keyName = string(char)
				} else {
					keyCode = uint16(key)
					if name, ok := keyNames[key]; ok {
						keyName = name
					} else {
						keyName = fmt.Sprintf("Key(%d)", key)
					}
				}

				_, err = db.Exec(
					"INSERT INTO keystrokes (key_code, key_name, timestamp, date, hour) VALUES (?, ?, ?, ?, ?)",
					keyCode, keyName, timestamp, date, hour,
				)
				if err != nil {
					log.Printf("Error saving keystroke: %v", err)
				}

				callbackMutex.RLock()
				if callback != nil {
					callback(keyCode, timestamp)
				}
				callbackMutex.RUnlock()
			}
		}
	}()

	return C.CString("")
}

//export StopListening
func StopListening() *C.char {
	if !isListening {
		return C.CString("Not listening")
	}

	close(stopListening)
	isListening = false
	return C.CString("")
}

//export GetStatsByDate
func GetStatsByDate(date *C.char) *C.char {
	if db == nil {
		return C.CString("{\"error\": \"Database not initialized\"}")
	}

	queryDate := C.GoString(date)
	rows, err := db.Query(
		"SELECT key_name, COUNT(*) as count FROM keystrokes WHERE date = ? GROUP BY key_name ORDER BY count DESC LIMIT 20",
		queryDate,
	)
	if err != nil {
		return C.CString(fmt.Sprintf("{\"error\": \"%v\"}", err))
	}
	defer rows.Close()

	result := "{\"data\": ["
	first := true
	for rows.Next() {
		var keyName string
		var count int
		if err := rows.Scan(&keyName, &count); err != nil {
			continue
		}
		if !first {
			result += ","
		}
		result += fmt.Sprintf("{\"key\": \"%s\", \"count\": %d}", keyName, count)
		first = false
	}
	result += "]}"

	return C.CString(result)
}

//export GetHourlyStats
func GetHourlyStats(date *C.char) *C.char {
	if db == nil {
		return C.CString("{\"error\": \"Database not initialized\"}")
	}

	queryDate := C.GoString(date)
	rows, err := db.Query(
		"SELECT hour, COUNT(*) as count FROM keystrokes WHERE date = ? GROUP BY hour ORDER BY hour",
		queryDate,
	)
	if err != nil {
		return C.CString(fmt.Sprintf("{\"error\": \"%v\"}", err))
	}
	defer rows.Close()

	counts := make([]int, 24)
	for rows.Next() {
		var hour, count int
		if err := rows.Scan(&hour, &count); err != nil {
			continue
		}
		if hour >= 0 && hour < 24 {
			counts[hour] = count
		}
	}

	result := "{\"data\": ["
	for i, count := range counts {
		if i > 0 {
			result += ","
		}
		result += fmt.Sprintf("{\"hour\": %d, \"count\": %d}", i, count)
	}
	result += "]}"

	return C.CString(result)
}

//export GetDailyStats
func GetDailyStats(startDate, endDate *C.char) *C.char {
	if db == nil {
		return C.CString("{\"error\": \"Database not initialized\"}")
	}

	start := C.GoString(startDate)
	end := C.GoString(endDate)
	rows, err := db.Query(
		"SELECT date, COUNT(*) as count FROM keystrokes WHERE date >= ? AND date <= ? GROUP BY date ORDER BY date",
		start, end,
	)
	if err != nil {
		return C.CString(fmt.Sprintf("{\"error\": \"%v\"}", err))
	}
	defer rows.Close()

	result := "{\"data\": ["
	first := true
	for rows.Next() {
		var date string
		var count int
		if err := rows.Scan(&date, &count); err != nil {
			continue
		}
		if !first {
			result += ","
		}
		result += fmt.Sprintf("{\"date\": \"%s\", \"count\": %d}", date, count)
		first = false
	}
	result += "]}"

	return C.CString(result)
}

//export CloseDatabase
func CloseDatabase() {
	if db != nil {
		db.Close()
		db = nil
	}
}

func main() {}
