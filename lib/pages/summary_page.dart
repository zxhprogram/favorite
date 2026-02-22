import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/ico_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
String newTagMimeType = '';

class summary_page extends StatefulWidget {
  summary_page({super.key});

  @override
  State<summary_page> createState() => _summary_pageState();
}

class _summary_pageState extends State<summary_page> {
  FormController c = FormController();

  TextEditingController titleController = .new();

  final newTagImg = signal<String?>(null);

  @override
  void dispose() {
    newTagImg.dispose();
    super.dispose();
  }

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

  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: .fill,
          opacity: 0.5,
          image: CachedNetworkImageProvider(
            'https://images.unsplash.com/photo-1771610947362-ade3a22642f2?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          ),
        ),
      ),
      child: Column(
        children: [
          Text('11:23').h1,
          Container(
            height: 60,
            margin: .symmetric(horizontal: 40, vertical: 10),
            child: TextField(
              placeholder: Text('输入以搜索'),
              style: .new(
                fontSize: 18,
                foreground: Paint()..color = Colors.blue,
              ),
              features: [
                .leading(
                  LayoutBuilder(
                    builder: (context, c) {
                      return Button.card(
                        child: FaIcon(FontAwesomeIcons.google),
                        onPressed: () {
                          showDropdown(
                            context: context,
                            widthConstraint: .anchorFixedSize,
                            alignment: .topCenter,
                            builder: (context) {
                              return DropdownMenu(
                                children: [
                                  MenuButton(
                                    child: FaIcon(FontAwesomeIcons.google),
                                    onPressed: (c) {},
                                  ),
                                  MenuButton(
                                    child: FaIcon(FontAwesomeIcons.microsoft),
                                    onPressed: (c) {},
                                  ),
                                  MenuButton(
                                    child: FaIcon(FontAwesomeIcons.yandex),
                                    onPressed: (c) {},
                                  ),
                                ],
                              );
                            },
                          ).future.then((_) {
                            // Called when the dropdown is closed.
                            if (kDebugMode) {
                              print('Closed');
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                .trailing(Icon(Icons.search, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
    // return SortableWrap(
    //   onSorted: (int oldIndex, int newIndex) {},
    //   children: [
    //     ...dataList.value.map((e) {
    //       return Container(width: w, height: w, child: Text(e.name));
    //     }),
    //     GestureDetector(
    //       onTap: () {
    //         showDialog(
    //           context: context,
    //           builder: (BuildContext context) {
    //             var url = newTagImg.watch(context);
    //             print('uuuu = $url');
    //             return Container(
    //               width: 600,
    //               height: 300,
    //               padding: .all(30),
    //               clipBehavior: .hardEdge,
    //               decoration: BoxDecoration(
    //                 color: Colors.white,
    //                 border: .all(color: Colors.gray, width: 1),
    //                 borderRadius: .all(.circular(50)),
    //                 boxShadow: [
    //                   .new(
    //                     color: Colors.gray,
    //                     offset: .new(10, 10),
    //                     blurRadius: 10,
    //                   ),
    //                 ],
    //               ),
    //               child: Column(
    //                 children: [
    //                   SizedBox(
    //                     width: 100,
    //                     height: 100,
    //                     child: fetchTagImg(url),
    //                   ),
    //                   gap(10),
    //                   Form(
    //                     controller: c,
    //                     child: FormTableLayout(
    //                       rows: [
    //                         FormField<String>(
    //                           key: FormKey(#url),
    //                           label: Text('书签地址'),
    //                           child: TextField(initialValue: '输入书签地址'),
    //                         ),
    //                         FormField<String>(
    //                           key: FormKey(#title),
    //                           label: Text('书签标题'),
    //                           child: TextField(
    //                             initialValue: '输入书签标题',
    //                             autofocus: true,
    //                             controller: titleController,
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                   gap(10),
    //                   Button.card(
    //                     child: Text('确认'),
    //                     onPressed: () async {
    //                       var url = c.getValue(FormKey(#url));
    //                       var data = await fetchUrlInfo(url);
    //                       titleController.text = data.title ?? '';
    //                       newTagImg.value = data.faviconUrl;
    //                       print('url = ${data.faviconUrl}');
    //                       newTagMimeType = data.mimeType;
    //                     },
    //                   ),
    //                 ],
    //               ),
    //             );
    //           },
    //         );
    //       },
    //       child: Container(width: w, height: w, color: Colors.red),
    //     ),
    //   ],
    // );
  }
}
