import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class IndexPage extends StatelessWidget {
  final Widget childPage;
  const IndexPage({required this.childPage, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Row(
        children: [
          SizedBox(width: 200, child: SlideBar()),
          Expanded(child: Container(child: childPage)),
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

              buildButton('大门', BootstrapIcons.grid, const ValueKey('/page2')),
              buildButton('Radio', BootstrapIcons.broadcast, const ValueKey(2)),
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
