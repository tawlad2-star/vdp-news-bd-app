import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'home.dart';

class BigCard extends StatelessWidget {
  final Post post;
  const BigCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: () => openPost(context, post),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            thumb(post.image, h: 210),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TimeRow(post),
              ]),
            ),
          ]),
        ),
      );
}

class NewsFeedView extends StatefulWidget {
  const NewsFeedView({super.key});
  @override
  State<NewsFeedView> createState() => _NewsFeedViewState();
}

class _NewsFeedViewState extends State<NewsFeedView> with AutomaticKeepAliveClientMixin {
  late Future<List<Post>> future = fetchPosts();
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => future = fetchPosts());
        await future;
      },
      child: FutureBuilder<List<Post>>(
        future: future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError || s.data == null || s.data!.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 200),
              Center(child: Text('লোড করা যায়নি। নিচে টেনে আবার চেষ্টা করুন।')),
            ]);
          }
          final posts = s.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: posts.length,
            itemBuilder: (_, i) => BigCard(post: posts[i]),
          );
        },
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});
  static const colors = [Color(0xFF00A651), Color(0xFFE02020), Color(0xFF14A08A), Color(0xFF5B6EE1)];
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(14),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.3,
        children: [
          for (var i = 0; i < sections.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openCategory(context, sections[i]),
              child: Container(
                padding: const EdgeInsets.all(14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(sections[i],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ctrl = TextEditingController();
  Future<List<Post>>? future;

  Future<List<Post>> search(String q) async {
    final r = await http.get(Uri.parse(
        '$blog/feeds/posts/default?q=${Uri.encodeQueryComponent(q)}&alt=json&max-results=40'));
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    return ((j['feed']['entry'] ?? []) as List).map((e) => Post.fromFeed(e as Map)).toList();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'খবর খুঁজুন', border: InputBorder.none),
            onSubmitted: (q) {
              if (q.trim().isEmpty) return;
              setState(() => future = search(q.trim()));
            },
          ),
        ),
        body: future == null
            ? const Center(child: Text('শিরোনাম বা শব্দ লিখে সার্চ করুন'))
            : FutureBuilder<List<Post>>(
                future: future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.hasError) return const Center(child: Text('সার্চ করা যায়নি'));
                  final l = s.data ?? [];
                  if (l.isEmpty) return const Center(child: Text('কোনো খবর পাওয়া যায়নি'));
                  return ListView(
                    padding: const EdgeInsets.all(10),
                    children: [for (final p in l) NewsCard(post: p)],
                  );
                },
              ),
      );
}
