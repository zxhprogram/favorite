import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/ico_viewer.dart';
import 'package:favorites/models/api.dart';
import 'package:favorites/services/api_service.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final newTagImg = signal<String?>(null);
  final folderNameController = TextEditingController();
  final titleController = TextEditingController();
  final userBookmarkList = signal<QueryAllBookmarksRes>(
    const QueryAllBookmarksRes(success: false),
  );
  final folderList = signal<QueryAllFoldersRes>(
    const QueryAllFoldersRes(success: false),
  );
  final expandedFolders = signal<Set<int>>({});
  final hoveredFolderId = signal<int?>(null);

  String newTagMimeType = '';
  FormController formController = FormController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final bookmarks = await queryAllBookmarks();
    final folders = await queryAllFolders();
    userBookmarkList.value = bookmarks;
    folderList.value = folders;
  }

  Widget _buildIcon(String mimeType, String url, {double size = 50}) {
    switch (mimeType) {
      case 'icon':
        return IcoViewer(url: url, key: ValueKey(url));
      case 'svg':
        return SvgPicture.network(url, width: size, height: size);
      case 'png':
        return CachedNetworkImage(imageUrl: url, width: size, height: size);
      default:
        return Icon(Icons.link, size: size);
    }
  }

  void _showCreateFolderDialog() {
    folderNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建文件夹'),
        content: TextField(
          controller: folderNameController,
          placeholder: const Text('请输入文件夹名称'),
          autofocus: true,
        ),
        actions: [
          Button.ghost(child: const Text('取消'), onPressed: () => context.pop()),
          Button.primary(
            child: const Text('创建'),
            onPressed: () async {
              final name = folderNameController.text.trim();
              if (name.isEmpty) return;
              await createFolder(CreateFolderReq(name: name));
              if (context.mounted) context.pop();
              await _fetchData();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateBookmarkDialog() {
    newTagImg.value = null;
    titleController.clear();
    showDialog(
      context: context,
      builder: (context) {
        final url = newTagImg.watch(context);
        return material.Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.gray,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: url != null
                        ? _buildIcon(newTagMimeType, url, size: 80)
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.gray[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.link, size: 40),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    controller: formController,
                    child: FormTableLayout(
                      rows: [
                        FormField<String>(
                          key: FormKey(#url),
                          label: const Text('书签地址'),
                          child: const TextField(placeholder: Text('输入书签地址')),
                        ),
                        FormField<String>(
                          key: FormKey(#title),
                          label: const Text('书签标题'),
                          child: TextField(
                            placeholder: const Text('输入书签标题'),
                            controller: titleController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button.ghost(
                        child: const Text('取消'),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Button.primary(
                        child: const Text('创建'),
                        onPressed: () async {
                          final url =
                              formController.getValue(FormKey(#url)) as String;
                          if (url.isEmpty) return;
                          final data = await fetchUrlInfo(url);
                          titleController.text = data.title ?? '';
                          newTagImg.value = data.faviconUrl;
                          newTagMimeType = data.mimeType;
                          await createBookmark(
                            BookmarkCreateReq(
                              name: data.title ?? url,
                              iconUrl: data.faviconUrl,
                              mimeType: data.mimeType,
                              url: url,
                              description: data.title,
                            ),
                          );
                          if (context.mounted) context.pop();
                          await _fetchData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFolderItem(FolderItem folder) {
    final isExpanded = expandedFolders.watch(context).contains(folder.id);
    final isHovered = hoveredFolderId.watch(context) == folder.id;
    final bookmarks = userBookmarkList.watch(context);
    final folderBookmarks =
        bookmarks.bookmarks?.where((b) => b.folderId == folder.id).toList() ??
        [];

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        hoveredFolderId.value = folder.id;
        if (!isExpanded) {
          expandedFolders.value = {...expandedFolders.value, folder.id};
        }
        return true;
      },
      onLeave: (_) {
        if (hoveredFolderId.value == folder.id) {
          hoveredFolderId.value = null;
        }
      },
      onAcceptWithDetails: (details) async {
        await moveBookmarkToFolder(
          MoveBookmarkToFolderReq(
            bookmarkId: details.data,
            folderId: folder.id,
          ),
        );
        hoveredFolderId.value = null;
        await _fetchData();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isHovered ? Colors.blue[50] : Colors.gray[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovered ? Colors.blue : Colors.gray[300],
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  final newSet = Set<int>.from(expandedFolders.value);
                  if (newSet.contains(folder.id)) {
                    newSet.remove(folder.id);
                  } else {
                    newSet.add(folder.id);
                  }
                  expandedFolders.value = newSet;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.folder_open : Icons.folder,
                        color: Colors.amber[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          folder.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${folderBookmarks.length}',
                        style: TextStyle(color: Colors.gray[600], fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Colors.gray[600],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded && folderBookmarks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: folderBookmarks
                        .map((bookmark) => _buildBookmarkChip(bookmark))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookmarkChip(BookmarksItem bookmark) {
    return Draggable<int>(
      data: bookmark.id,
      feedback: material.Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: _buildIcon(
                  bookmark.mimeType,
                  bookmark.iconUrl,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(bookmark.name, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildBookmarkItem(bookmark),
      ),
      child: _buildBookmarkItem(bookmark),
    );
  }

  Widget _buildBookmarkItem(BookmarksItem bookmark) {
    return HoverCard(
      hoverBuilder: (context) {
        return SurfaceCard(
          child: Basic(
            leading: _buildIcon(bookmark.mimeType, bookmark.iconUrl),
            title: Text(bookmark.name),
            content: Text(
              bookmark.description.isNotEmpty
                  ? bookmark.description
                  : bookmark.url,
            ),
          ),
        ).sized(width: 300);
      },
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(bookmark.url)),
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.gray[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildIcon(bookmark.mimeType, bookmark.iconUrl),
              ),
              const SizedBox(height: 4),
              Text(
                bookmark.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    final folders = folderList.watch(context);
    final bookmarks = userBookmarkList.watch(context);
    final items = <Widget>[];

    if (folders.folders != null) {
      for (final folder in folders.folders!) {
        items.add(
          SizedBox(width: double.infinity, child: _buildFolderItem(folder)),
        );
      }
    }

    if (bookmarks.bookmarks != null) {
      final rootBookmarks = bookmarks.bookmarks!.where(
        (b) => b.folderId == null,
      );
      for (final bookmark in rootBookmarks) {
        items.add(_buildBookmarkChip(bookmark));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: Colors.transparent,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          Object? dropdownController;
          dropdownController = showDropdown(
            context: context,
            position: details.globalPosition,
            builder: (context) {
              return DropdownMenu(
                children: [
                  MenuButton(
                    leading: const Icon(Icons.folder),
                    child: const Text('新建文件夹'),
                    onPressed: (_) {
                      (dropdownController as dynamic).remove();
                      Future.microtask(() => _showCreateFolderDialog());
                    },
                  ),
                  MenuButton(
                    leading: const Icon(Icons.link),
                    child: const Text('新建书签'),
                    onPressed: (_) {
                      (dropdownController as dynamic).remove();
                      Future.microtask(() => _showCreateBookmarkDialog());
                    },
                  ),
                  const MenuDivider(),
                  MenuButton(
                    leading: const Icon(Icons.refresh),
                    child: const Text('刷新'),
                    onPressed: (_) {
                      (dropdownController as dynamic).remove();
                      _fetchData();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._buildItems(),
                  Button.ghost(
                    alignment: Alignment.center,
                    onPressed: _showCreateBookmarkDialog,
                    child: const FaIcon(Icons.add, size: 50),
                  ).sized(width: 100, height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
