import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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
        crossAxisAlignment: .stretch,
        children: [
          Text('11:23', textAlign: .center).h1,
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
          Container(
            margin: .symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text('最近访问').bold,
                SingleChildScrollView(
                  scrollDirection: .horizontal,
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: .start,
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                        color: Colors.red,
                        child: Column(
                          children: [
                            Image.network(
                              'https://sunarya-thito.github.io/shadcn_flutter/favicon.png',
                              width: 40,
                              height: 40,
                              fit: .cover,
                            ),
                            Text('github'),
                          ],
                        ),
                      ),
                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),

                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),

                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),

                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),
                      Container(width: 100, height: 100, color: Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
