import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/ico_viewer.dart';
import 'package:favorites/models/api.dart';
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
        return CachedNetworkImage(imageUrl: url, width: 50, height: 50);
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
            HoverCard(
              hoverBuilder: (context) {
                return SurfaceCard(
                  child: Basic(
                    leading: icon(e.mimeType, e.iconUrl),
                    title: Text('@flutter'),
                    content: Text(
                      'The Flutter SDK provides the tools to build beautiful apps for mobile, web, and desktop from a single codebase.',
                    ),
                  ),
                ).sized(width: 300);
              },
              child: icon(e.mimeType, e.iconUrl),
            ),
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
      onSorted: (int oldIndex, int newIndex) {
        print(
          'old = ${userBookmarkList.value.bookmarks![oldIndex]}, new = ${userBookmarkList.value.bookmarks![newIndex]}',
        );
        print('before = ${userBookmarkList.value.bookmarks}');
        var element = userBookmarkList.value.bookmarks![oldIndex];
        userBookmarkList.value.bookmarks!.removeAt(oldIndex);
        userBookmarkList.value.bookmarks!.insert(newIndex, element);
        print('after = ${userBookmarkList.value.bookmarks}');
        var req = <SortItem>[];
        for (var i = 0; i < userBookmarkList.value.bookmarks!.length; i++) {
          var id = userBookmarkList.value.bookmarks![i].id;
          req.add(.new(id: id, sortOrder: i));
        }
        sortBookmarks(.new(bookmarks: req));
      },
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
