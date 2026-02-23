import 'package:favorites/models/api.dart';
import 'package:favorites/services/api_service.dart';
import 'package:flutter/material.dart' as  m;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class GithubPage extends StatefulWidget {
  @override
  State<GithubPage> createState() => _GithubPageState();
}

class _GithubPageState extends State<GithubPage> {
  var list = signal<List<Repository>>([]);
  var isLoading = signal(true);
  var error = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      isLoading.value = true;
      error.value = null;
      var r = await githubTrending(GithubTrendingReq());
      list.value = r.repositories;
    } catch (e) {
      error.value = '获取数据失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    list.dispose();
    isLoading.dispose();
    error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var data = list.watch(context);
    var loading = isLoading.watch(context);
    var errorMsg = error.watch(context);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorMsg != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(child: Text(errorMsg!)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => error.value = null,
                    variance: ButtonStyle.ghost(),
                  ),
                ],
              ),
            ),
          if (loading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载GitHub Trending数据...'),
                  ],
                ),
              ),
            )
          else if (data.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.gray[400]),
                  SizedBox(height: 16),
                  Text('暂无数据', style: TextStyle(color: Colors.gray[600])),
                  SizedBox(height: 8),
                  Button(
                    onPressed: _fetchData,
                    style: ButtonStyle.primary(),
                    child: Text('重新加载'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final repo = data[index];
                  return _buildRepositoryCard(repo, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepositoryCard(Repository repo, int index) {
    return Card(
      padding: EdgeInsets.only(bottom: 12),
      // duration: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 排名徽章
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(index + 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // 头像
                if (repo.avatar != null && repo.avatar!.isNotEmpty)
                  m.CircleAvatar(
                    backgroundImage: NetworkImage(repo.avatar!),
                    radius: 20,
                  )
                else
                  m.CircleAvatar(
                    backgroundColor: Colors.gray[300],
                    radius: 20,
                    child: Icon(Icons.code, color: Colors.white),
                  ),
                SizedBox(width: 12),
                // 仓库信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${repo.author}/${repo.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (repo.description != null &&
                          repo.description!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            repo.description!,
                            style: TextStyle(
                              color: Colors.gray[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // 统计信息
            Row(
              children: [
                if (repo.language != null && repo.language!.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getLanguageColor(repo.language!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        repo.language!,
                        style: TextStyle(color: Colors.gray[600], fontSize: 12),
                      ),
                      SizedBox(width: 16),
                    ],
                  ),
                Icon(Icons.star, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  _formatNumber(repo.stars ?? 0),
                  style: TextStyle(color: Colors.gray[600], fontSize: 12),
                ),
                SizedBox(width: 16),
                Icon(Icons.call_split, size: 14, color: Colors.gray),
                SizedBox(width: 4),
                Text(
                  _formatNumber(repo.forks ?? 0),
                  style: TextStyle(color: Colors.gray[600], fontSize: 12),
                ),
                if (repo.stars > 0) ...[
                  SizedBox(width: 16),
                  Icon(Icons.trending_up, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '${repo.stars} stars today',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.gray[600]!;
    if (rank == 3) return Colors.orange[800]!;
    return Colors.blue[600]!;
  }

  Color _getLanguageColor(String language) {
    final colors = {
      'JavaScript': Colors.yellow[700]!,
      'TypeScript': Colors.blue[700]!,
      'Python': Colors.blue[400]!,
      'Java': Colors.red[600]!,
      'Go': Colors.cyan[600]!,
      'Rust': Colors.orange[800]!,
      'C++': Colors.pink[600]!,
      'C#': Colors.purple[600]!,
      'PHP': Colors.purple[400]!,
      'Ruby': Colors.red[700]!,
      'Swift': Colors.orange[500]!,
      'Kotlin': Colors.orange[700]!,
      'Dart': Colors.blue[400]!,
    };
    return colors[language] ?? Colors.gray[400]!;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
