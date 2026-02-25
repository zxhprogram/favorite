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

  @override
  void dispose() {
    isHoverOnAvatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var r = loginInfo.watch(context);
    var hovered = isHoverOnAvatar.watch(context);
    return Scaffold(
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: .all(5),
                  child: Column(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onHover: (_) {
                          isHoverOnAvatar.value = true;
                        },
                        onExit: (_) {
                          isHoverOnAvatar.value = false;
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          child: Stack(
                            children: [
                              (r.isLogin && r.currentUserAvatar != null)
                                  ? Image.network(r.currentUserAvatar!)
                                  : Container(color: Colors.red),
                              hovered
                                  ? Positioned(
                                      left: (70 - 20) / 2,
                                      top: (70 - 20) / 2,
                                      width: 20,
                                      height: 20,
                                      child: Button.fixed(
                                        alignment: .center,
                                        child: Icon(Icons.edit),
                                        onPressed: () async {
                                          var file = await FilePicker.platform
                                              .pickFiles(
                                                type: .image,
                                                allowedExtensions: [
                                                  'png',
                                                  'jpg',
                                                  'jpeg',
                                                ],
                                                dialogTitle: '选择头像',
                                                allowMultiple: false,
                                              );
                                          if (file == null) {
                                            return;
                                          }
                                          print(
                                            'file.names = ${file.names},file.paths = ${file.paths}',
                                          );
                                          var result = await uploadAvatar(
                                            File(file.paths[0]!),
                                          );
                                          if (result.success) {
                                            loginInfo.value = .new(
                                              isLogin: loginInfo.value.isLogin,
                                              currentUserName: loginInfo
                                                  .value
                                                  .currentUserName,
                                              token: loginInfo.value.token,
                                              currentUserAvatar:
                                                  'http://localhost:8081${result.url}',
                                            );
                                          }
                                        },
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                      Button.ghost(
                        child: r.isLogin
                            ? Text(r.currentUserName!)
                            : Text('点击登录'),
                        onPressed: () {
                          print(1);
                          context.push('/login');
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: SlideBar()),
              ],
            ),
          ),
          Expanded(child: Container(child: widget.childPage)),
        ],
      ),
    );
  }
}

var selected = Signal<Key?>(ValueKey('/'));

class SlideBar extends StatelessWidget {
  const SlideBar({super.key});

  Widget buildButton(String label, IconData icon, Key key) {
    return NavigationItem(key: key, label: Text(label), child: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    var v = selected.watch(context);
    return OutlinedContainer(
      child: NavigationSidebar(
        selectedKey: v,
        onSelected: (key) {
          selected.value = key;
          if (context.canPop()) {
            context.pop();
          }
          context.go((key as ValueKey).value);
        },
        children: [
          NavigationGroup(
            label: const Text('Discovery'),
            children: [
              buildButton(
                '总览',
                BootstrapIcons.thermometerHalf,
                const ValueKey('/'),
              ),
              buildButton(
                '书签',
                BootstrapIcons.grid,
                const ValueKey('/bookmarks'),
              ),
              buildButton('github', LucideIcons.github, const ValueKey('/github')),
              buildButton('keystats', LucideIcons.github, const ValueKey('/keystats')),
            ],
          ),
          const NavigationGap(24),
          const NavigationDivider(),
          NavigationGroup(
            label: const Text('Library'),
            children: [
              buildButton(
                'Playlist',
                BootstrapIcons.musicNoteList,
                const ValueKey(3),
              ),
              buildButton('Songs', BootstrapIcons.musicNote, const ValueKey(4)),
              buildButton('For You', BootstrapIcons.person, const ValueKey(5)),
              buildButton('Artists', BootstrapIcons.mic, const ValueKey(6)),
              buildButton('Albums', BootstrapIcons.record2, const ValueKey(7)),
            ],
          ),
          const NavigationGap(24),
          const NavigationDivider(),
        ],
      ),
    );
  }
}
