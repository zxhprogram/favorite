import 'package:favorites/ico_viewer.dart';
import 'package:favorites/services/api_service.dart';
import 'package:flutter_sortable_wrap/sortable_wrap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

final dataList = signal(<Item>[
  .new(name: 'github', url: '', icon: ''),
  .new(name: 'alibaba', url: '', icon: ''),
  .new(name: 'google', url: '', icon: ''),
]);

class Item {
  String name;
  String url;
  String icon;
  Item({required this.name, required this.url, required this.icon});
}

const w = 100.0;
final newTagImg = signal<String?>(null);
String newTagMimeType = '';

class Page1 extends StatelessWidget {
  Page1({super.key});
  FormController c = FormController();
  TextEditingController titleController = .new();
  Widget fetchTagImg(String? url) {
    switch (newTagMimeType) {
      case 'icon':
        return IcoViewer(url: url!, key: ValueKey(url));
      case 'svg':
        return SvgPicture.network(url!, width: 80, height: 80);
      case 'png':
        return Image.network(url!);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SortableWrap(
      onSorted: (int oldIndex, int newIndex) {},
      children: [
        ...dataList.value.map((e) {
          return Container(width: w, height: w, child: Text(e.name));
        }),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                var url = newTagImg.watch(context);
                print('uuuu = $url');
                return Container(
                  width: 600,
                  height: 300,
                  padding: .all(30),
                  clipBehavior: .hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: .all(color: Colors.gray, width: 1),
                    borderRadius: .all(.circular(50)),
                    boxShadow: [
                      .new(
                        color: Colors.gray,
                        offset: .new(10, 10),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: fetchTagImg(url),
                      ),
                      gap(10),
                      Form(
                        controller: c,
                        child: FormTableLayout(
                          rows: [
                            FormField<String>(
                              key: FormKey(#url),
                              label: Text('书签地址'),
                              child: TextField(initialValue: '输入书签地址'),
                            ),
                            FormField<String>(
                              key: FormKey(#title),
                              label: Text('书签标题'),
                              child: TextField(
                                initialValue: '输入书签标题',
                                autofocus: true,
                                controller: titleController,
                              ),
                            ),
                          ],
                        ),
                      ),
                      gap(10),
                      Button.card(
                        child: Text('确认'),
                        onPressed: () async {
                          var url = c.getValue(FormKey(#url));
                          var data = await fetchUrlInfo(url);
                          titleController.text = data.title ?? '';
                          newTagImg.value = data.faviconUrl;
                          print('url = ${data.faviconUrl}');
                          newTagMimeType = data.mimeType;
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(width: w, height: w, color: Colors.red),
        ),
      ],
    );
  }
}
