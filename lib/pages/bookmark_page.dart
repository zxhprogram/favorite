import 'package:favorites/ico_viewer.dart';
import 'package:favorites/services/api_service.dart';
import 'package:flutter_sortable_wrap/sortable_wrap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class BookmarkPage extends StatefulWidget {
  BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final newTagImg = signal<String?>(null);
  FormController c = FormController();
  String newTagMimeType = '';

  TextEditingController titleController = .new();
  final userBookmarkList = signal<QueryAllBookmarksRes>(.new(success: false));

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
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    userBookmarkList.value = await queryAllBookmarks();
  }

  Widget icon(String mimeType, String url) {
    switch (mimeType) {
      case 'icon':
        return IcoViewer(url: url, key: ValueKey(url));
      case 'svg':
        return SvgPicture.network(url, width: 50, height: 50);
      case 'png':
        return Image.network(url, width: 50, height: 50);
      default:
        return Container();
    }
  }

  List<Widget> expandItemList(QueryAllBookmarksRes res) {
    if (res.bookmarks == null) {
      return [];
    }
    return res.bookmarks!.map((e) {
      return Container(
        width: 100,
        height: 100,
        child: Column(
          children: [
            icon(e.mimeType, e.iconUrl),
            Text(e.name, maxLines: 1, style: .new(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var dataSet = userBookmarkList.watch(context);
    return SortableWrap(
      onSorted: (int oldIndex, int newIndex) {},
      children: [
        ...expandItemList(dataSet),
        Button.ghost(
          alignment: .center,
          child: FaIcon(Icons.add, size: 50),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                var url = newTagImg.watch(context);
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
                        child: Text('创建'),
                        onPressed: () async {
                          var url = c.getValue(FormKey(#url)) as String;
                          var data = await fetchUrlInfo(url);
                          titleController.text = data.title ?? '';
                          newTagImg.value = data.faviconUrl;
                          print('url = ${data.faviconUrl}');
                          newTagMimeType = data.mimeType;
                          print(
                            'url = ${data.faviconUrl}, title = ${data.title}',
                          );
                          await createBookmark(
                            .new(
                              name: data.title!,
                              iconUrl: data.faviconUrl,
                              mimeType: data.mimeType,
                              url: url,
                              description: data.title,
                            ),
                          );
                          await _fetchData();
                          context.pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ).sized(width: 100, height: 100),
      ],
    );
  }
}
