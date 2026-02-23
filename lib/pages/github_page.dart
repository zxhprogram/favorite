import 'package:favorites/models/api.dart';
import 'package:favorites/services/api_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_core.dart' hide signal;
import 'package:signals/signals_flutter.dart';

class GithubPage extends StatefulWidget {
  @override
  State<GithubPage> createState() => _GithubPageState();
}

class _GithubPageState extends State<GithubPage> {
  var list = signal<List<Repository>>([]);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    var r = await githubTrending(.new());
    list.value = r.repositories;
  }

  @override
  void dispose() {
    list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var data = list.watch(context);
    return Container(
      child: ListView.builder(
        itemBuilder: (c, i) {
          print('list = ${data.length}, current = $i');
          return Text(data[i].name);
        },
        itemCount: data.length,
      ),
    );
  }
}
