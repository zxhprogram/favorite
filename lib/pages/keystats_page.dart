import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';

// FFI bindings
typedef InitDatabaseC = Pointer<Utf8> Function(Pointer<Utf8> dbPath);
typedef InitDatabaseDart = Pointer<Utf8> Function(Pointer<Utf8> dbPath);

typedef StartListeningC = Pointer<Utf8> Function();
typedef StartListeningDart = Pointer<Utf8> Function();

typedef StopListeningC = Pointer<Utf8> Function();
typedef StopListeningDart = Pointer<Utf8> Function();

typedef GetStatsByDateC = Pointer<Utf8> Function(Pointer<Utf8> date);
typedef GetStatsByDateDart = Pointer<Utf8> Function(Pointer<Utf8> date);

typedef GetHourlyStatsC = Pointer<Utf8> Function(Pointer<Utf8> date);
typedef GetHourlyStatsDart = Pointer<Utf8> Function(Pointer<Utf8> date);

class KeystatsPage extends StatefulWidget {
  const KeystatsPage({super.key});

  @override
  State<KeystatsPage> createState() => _KeystatsPageState();
}

class _KeystatsPageState extends State<KeystatsPage>
    with SingleTickerProviderStateMixin {
  DynamicLibrary? _dll;
  bool _isListening = false;
  bool _dllLoaded = false;
  String _status = 'Initializing...';

  final _selectedDate = signal<DateTime>(DateTime.now());
  final _keyStats = signal<Map<String, int>>({});
  final _hourlyStats = signal<List<int>>(List.filled(24, 0));
  final _totalKeystrokes = signal<int>(0);
  final _topKeys = signal<List<MapEntry<String, int>>>([]);

  late material.TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = material.TabController(length: 3, vsync: this);
    _initDll();
  }

  void _initDll() {
    try {
      final dllPath = '${Directory.current.path}/plugins/keylogger.dll';
      _dll = DynamicLibrary.open(dllPath);

      final initDb = _dll!.lookupFunction<InitDatabaseC, InitDatabaseDart>(
        'InitDatabase',
      );
      final dbPath = '${Directory.current.path}/plugins/keystrokes.db'
          .toNativeUtf8();
      final result = initDb(dbPath);
      final error = result.toDartString();
      calloc.free(dbPath);

      if (error.isNotEmpty) {
        setState(() {
          _status = 'Database error: $error';
        });
        return;
      }

      setState(() {
        _dllLoaded = true;
        _status = 'Ready';
      });

      _loadStats();
    } catch (e) {
      setState(() {
        _status = 'Error loading DLL: $e';
      });
    }
  }

  void _toggleListening() {
    if (_dll == null) return;

    if (_isListening) {
      final stopListening = _dll!
          .lookupFunction<StopListeningC, StopListeningDart>('StopListening');
      final result = stopListening();
      final error = result.toDartString();

      if (error.isNotEmpty) {
        setState(() {
          _status = 'Error: $error';
        });
        return;
      }

      setState(() {
        _isListening = false;
        _status = 'Stopped';
      });
    } else {
      final startListening = _dll!
          .lookupFunction<StartListeningC, StartListeningDart>(
            'StartListening',
          );
      final result = startListening();
      final error = result.toDartString();

      if (error.isNotEmpty) {
        setState(() {
          _status = 'Error: $error';
        });
        return;
      }

      setState(() {
        _isListening = true;
        _status = 'Listening...';
      });
    }

    Future.delayed(const Duration(seconds: 1), _loadStats);
  }

  void _loadStats() {
    if (_dll == null) return;

    final date = _selectedDate.value;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Load key stats
    final getStats = _dll!.lookupFunction<GetStatsByDateC, GetStatsByDateDart>(
      'GetStatsByDate',
    );
    final dateNative = dateStr.toNativeUtf8();
    final statsResult = getStats(dateNative);
    final statsJson = statsResult.toDartString();
    calloc.free(dateNative);

    // Load hourly stats
    final getHourly = _dll!.lookupFunction<GetHourlyStatsC, GetHourlyStatsDart>(
      'GetHourlyStats',
    );
    final hourlyNative = dateStr.toNativeUtf8();
    final hourlyResult = getHourly(hourlyNative);
    final hourlyJson = hourlyResult.toDartString();
    calloc.free(hourlyNative);

    _parseStats(statsJson, hourlyJson);
  }

  void _parseStats(String statsJson, String hourlyJson) {
    try {
      // Parse key stats
      final keyStats = <String, int>{};
      if (statsJson.contains('"data"')) {
        final dataMatch = RegExp(r'"data":\s*\[(.*?)\]').firstMatch(statsJson);
        if (dataMatch != null) {
          final dataStr = dataMatch.group(1)!;
          final entries = RegExp(r'\{[^}]+\}').allMatches(dataStr);
          for (final entry in entries) {
            final entryStr = entry.group(0)!;
            final keyMatch = RegExp(r'"key":\s*"([^"]+)"').firstMatch(entryStr);
            final countMatch = RegExp(r'"count":\s*(\d+)').firstMatch(entryStr);
            if (keyMatch != null && countMatch != null) {
              keyStats[keyMatch.group(1)!] = int.parse(countMatch.group(1)!);
            }
          }
        }
      }

      // Parse hourly stats
      final hourlyStats = List.filled(24, 0);
      if (hourlyJson.contains('"data"')) {
        final dataMatch = RegExp(r'"data":\s*\[(.*?)\]').firstMatch(hourlyJson);
        if (dataMatch != null) {
          final dataStr = dataMatch.group(1)!;
          final entries = RegExp(r'\{[^}]+\}').allMatches(dataStr);
          for (final entry in entries) {
            final entryStr = entry.group(0)!;
            final hourMatch = RegExp(r'"hour":\s*(\d+)').firstMatch(entryStr);
            final countMatch = RegExp(r'"count":\s*(\d+)').firstMatch(entryStr);
            if (hourMatch != null && countMatch != null) {
              final hour = int.parse(hourMatch.group(1)!);
              if (hour >= 0 && hour < 24) {
                hourlyStats[hour] = int.parse(countMatch.group(1)!);
              }
            }
          }
        }
      }

      final total = keyStats.values.fold<int>(0, (sum, count) => sum + count);
      final topKeys = keyStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _keyStats.value = keyStats;
      _hourlyStats.value = hourlyStats;
      _totalKeystrokes.value = total;
      _topKeys.value = topKeys.take(10).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Parse error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isListening && _dll != null) {
      try {
        final stopListening = _dll!
            .lookupFunction<StopListeningC, StopListeningDart>('StopListening');
        stopListening();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      backgroundColor: Colors.gray[900],
      body: Column(
        children: [
          _buildHeader(),
          _buildControls(),
          Expanded(
            child: material.TabBarView(
              controller: _tabController,
              children: [
                _buildHeatmapView(),
                _buildRadialView(),
                _buildTimelineView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700], Colors.blue[700]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keystroke Analytics',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: $_status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              _buildTotalCounter(),
            ],
          ),
          const SizedBox(height: 16),
          material.TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              material.Tab(text: 'Heatmap'),
              material.Tab(text: 'Radial'),
              material.Tab(text: 'Timeline'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCounter() {
    return Watch((context) {
      final total = _totalKeystrokes.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              'TOTAL KEYS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total.toString(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Button(
            style: ButtonStyle.primary(),
            onPressed: _dllLoaded ? _toggleListening : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isListening ? Icons.stop : Icons.play_arrow),
                const SizedBox(width: 8),
                Text(_isListening ? 'Stop' : 'Start'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Button(
            style: ButtonStyle.secondary(),
            onPressed: _dllLoaded ? _loadStats : null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Refresh'),
              ],
            ),
          ),
          const Spacer(),
          DatePicker(
            value: _selectedDate.watch(context),
            onChanged: (date) {
              if (date != null) {
                _selectedDate.value = date;
                _loadStats();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHourlyHeatmap(),
          const SizedBox(height: 24),
          _buildKeyFrequencyBars(),
        ],
      ),
    );
  }

  Widget _buildHourlyHeatmap() {
    return Watch((context) {
      final hourly = _hourlyStats.value;
      final maxCount = hourly.isEmpty ? 1 : hourly.reduce(math.max);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hourly Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(24, (hour) {
                  final count = hourly[hour];
                  final intensity = maxCount > 0 ? count / maxCount : 0.0;

                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.gray[800],
                        Colors.purple[500],
                        intensity,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        hour.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 10,
                          color: intensity > 0.5
                              ? Colors.white
                              : Colors.gray[400],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildKeyFrequencyBars() {
    return Watch((context) {
      final topKeys = _topKeys.value;
      if (topKeys.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No data available')),
          ),
        );
      }

      final maxCount = topKeys.first.value;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Keys',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...topKeys.map((entry) {
                final percentage = entry.value / maxCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.gray[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple[500],
                                      Colors.blue[500],
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: Colors.gray[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRadialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Watch((context) {
        final topKeys = _topKeys.value;
        if (topKeys.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No data available')),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Key Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 300,
                  child: CustomPaint(
                    size: const material.Size(300, 300),
                    painter: RadialChartPainter(topKeys),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: topKeys.map((entry) {
                    final index = topKeys.indexOf(entry);
                    final colors = [
                      Colors.purple[500],
                      Colors.blue[500],
                      Colors.green[500],
                      Colors.orange[500],
                      Colors.red[500],
                      Colors.cyan[500],
                      Colors.pink[500],
                      Colors.yellow[500],
                      Colors.indigo[500],
                      Colors.teal[500],
                    ];
                    final color = colors[index % colors.length];

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${entry.key}: ${entry.value}'),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimelineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Watch((context) {
        final hourly = _hourlyStats.value;
        final maxCount = hourly.isEmpty ? 1 : hourly.reduce(math.max);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const material.Size(double.infinity, 200),
                    painter: TimelinePainter(hourly, maxCount),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '00:00',
                      style: TextStyle(color: Colors.gray[500], fontSize: 12),
                    ),
                    Text(
                      '06:00',
                      style: TextStyle(color: Colors.gray[500], fontSize: 12),
                    ),
                    Text(
                      '12:00',
                      style: TextStyle(color: Colors.gray[500], fontSize: 12),
                    ),
                    Text(
                      '18:00',
                      style: TextStyle(color: Colors.gray[500], fontSize: 12),
                    ),
                    Text(
                      '23:59',
                      style: TextStyle(color: Colors.gray[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class RadialChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;

  RadialChartPainter(this.data);

  @override
  void paint(Canvas canvas, material.Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;

    final total = data.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return;

    final colors = [
      Colors.purple[500],
      Colors.blue[500],
      Colors.green[500],
      Colors.orange[500],
      Colors.red[500],
      Colors.cyan[500],
      Colors.pink[500],
      Colors.yellow[500],
      Colors.indigo[500],
      Colors.teal[500],
    ];

    var startAngle = -math.pi / 2;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw label
      final labelAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.7;
      final labelX = center.dx + math.cos(labelAngle) * labelRadius;
      final labelY = center.dy + math.sin(labelAngle) * labelRadius;

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );

      startAngle += sweepAngle;
    }

    // Draw center hole
    final centerPaint = Paint()
      ..color = Colors.gray[900]
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TimelinePainter extends CustomPainter {
  final List<int> hourlyData;
  final int maxCount;

  TimelinePainter(this.hourlyData, this.maxCount);

  @override
  void paint(Canvas canvas, material.Size size) {
    final paint = Paint()
      ..color = Colors.purple[500]
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.purple[500].withValues(alpha: 0.3),
          Colors.purple[500].withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (hourlyData.length - 1);

    for (var i = 0; i < hourlyData.length; i++) {
      final x = i * stepX;
      final y =
          size.height -
          (hourlyData[i] / maxCount.toDouble()) * size.height * 0.8;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.purple[300]
      ..style = PaintingStyle.fill;

    for (var i = 0; i < hourlyData.length; i++) {
      final x = i * stepX;
      final y =
          size.height -
          (hourlyData[i] / maxCount.toDouble()) * size.height * 0.8;

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
