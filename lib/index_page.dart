import 'dart:io';

import 'package:favorites/main.dart';
import 'package:favorites/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class IndexPage extends StatefulWidget {
  final Widget childPage;

  const IndexPage({required this.childPage, super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final isHoverOnAvatar = Signal(false);
  final expanded = Signal(true);

  @override
  void dispose() {
    isHoverOnAvatar.dispose();
    expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var r = loginInfo.watch(context);
    var hovered = isHoverOnAvatar.watch(context);
    var isExpanded = expanded.watch(context);

    return Scaffold(
      child: Row(
        children: [
          NavigationRail(
            expanded: isExpanded,
            labelType: NavigationLabelType.expanded,
            labelPosition: NavigationLabelPosition.end,
            alignment: NavigationRailAlignment.start,
            expandedSize: 220,
            header: [
              if (isExpanded)
                Builder(
                  builder: (context) {
                    return NavigationSlot(
                      leading: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onHover: (_) => isHoverOnAvatar.value = true,
                        onExit: (_) => isHoverOnAvatar.value = false,
                        child: Container(
                          width: 40,
                          height: 40,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child:
                                    (r.isLogin && r.currentUserAvatar != null)
                                    ? Image.network(
                                        r.currentUserAvatar!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.red,
                                      ),
                              ),
                              if (hovered)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        r.isLogin ? r.currentUserName! : '点击登录',
                      ).medium.small,
                      subtitle: r.isLogin
                          ? const Text('已登录').xSmall.normal
                          : const Text('未登录').xSmall.normal,
                      trailing: const Icon(
                        LucideIcons.chevronsUpDown,
                      ).iconSmall,
                      onPressed: () {
                        if (!r.isLogin) {
                          context.push('/login');
                        } else {
                          _showUserMenu(context);
                        }
                      },
                    );
                  },
                )
              else
                NavigationItem(
                  selected: false,
                  onChanged: (_) {
                    if (!r.isLogin) {
                      context.push('/login');
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onHover: (_) => isHoverOnAvatar.value = true,
                    onExit: (_) => isHoverOnAvatar.value = false,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: (r.isLogin && r.currentUserAvatar != null)
                            ? Image.network(
                                r.currentUserAvatar!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: Colors.red,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
            footer: [
              NavigationItem(
                selected: false,
                onChanged: (_) => expanded.value = !isExpanded,
                child: Icon(
                  isExpanded
                      ? LucideIcons.panelLeftClose
                      : LucideIcons.panelLeft,
                ),
              ),
            ],
            children: [
              _buildLabel('Discovery', isExpanded),
              _buildButton(
                '总览',
                BootstrapIcons.thermometerHalf,
                '/',
                isExpanded,
              ),
              _buildButton('书签', BootstrapIcons.grid, '/bookmarks', isExpanded),
              _buildButton('Github', LucideIcons.github, '/github', isExpanded),
              const NavigationDivider(),
              _buildLabel('Library', isExpanded),
              _buildButton(
                'Playlist',
                BootstrapIcons.musicNoteList,
                '/playlist',
                isExpanded,
              ),
              _buildButton(
                'Songs',
                BootstrapIcons.musicNote,
                '/songs',
                isExpanded,
              ),
              _buildButton(
                'For You',
                BootstrapIcons.person,
                '/foryou',
                isExpanded,
              ),
              const NavigationDivider(),
            ],
          ),
          const VerticalDivider(),
          Expanded(child: widget.childPage),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, bool isExpanded) {
    if (!isExpanded) return const SizedBox.shrink();
    return NavigationGroup(
      labelAlignment: Alignment.centerLeft,
      label: Text(label).semiBold.muted.xSmall,
      children: const [],
    );
  }

  Widget _buildButton(
    String text,
    IconData icon,
    String route,
    bool isExpanded,
  ) {
    final isSelected = GoRouterState.of(context).uri.path == route;

    return NavigationItem(
      label: isExpanded ? Text(text) : null,
      selected: isSelected,
      selectedStyle: const ButtonStyle.primaryIcon(),
      onChanged: (selected) {
        if (selected) {
          context.go(route);
        }
      },
      child: Icon(icon),
    );
  }

  void _showUserMenu(BuildContext context) {
    showDropdown(
      context: context,
      anchorAlignment: AlignmentDirectional.centerEnd,
      alignment: AlignmentDirectional.centerStart,
      offset: const Offset(16, 0),
      builder: (context) {
        return DropdownMenu(
          children: [
            MenuButton(
              leading: const Icon(Icons.person),
              child: const Text('更换头像'),
              onPressed: (ctx) async {
                Navigator.of(ctx).pop();
                var file = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowedExtensions: ['png', 'jpg', 'jpeg'],
                  dialogTitle: '选择头像',
                  allowMultiple: false,
                );
                if (file == null) return;

                var result = await uploadAvatar(File(file.paths[0]!));
                if (result.success) {
                  loginInfo.value = LoginInfo(
                    isLogin: loginInfo.value.isLogin,
                    currentUserName: loginInfo.value.currentUserName,
                    token: loginInfo.value.token,
                    currentUserAvatar: 'http://localhost:8081${result.url}',
                  );
                }
              },
            ),
            const MenuDivider(),
            MenuButton(
              leading: const Icon(Icons.logout),
              child: const Text('退出登录'),
              onPressed: (ctx) {
                Navigator.of(ctx).pop();
                loginInfo.value = LoginInfo(isLogin: false);
                context.go('/');
              },
            ),
          ],
        );
      },
    );
  }
}
