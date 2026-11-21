import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const blog = 'https://vdpnewsbd.blogspot.com';
const labels = ['সব খবর', 'Ansar VDP News', 'AVUB News', 'Head Quarter News', 'VDP News'];

void main() => runApp(const NewsApp());

class Post {
  final String title, html, link, date;
  Post(this.title, this.html, this.link, this.date);

  factory Post.fromJson(Map e) {
    final links = e['link'] as List;
    final alt = links.firstWhere((l) => l['rel'] == 'alternate', orElse: () => links.first);
    return Post(
      e['title']['\$t'],
      (e['content']?['\$t'] ?? e['summary']?['\$t'] ?? '') as String,
      alt['href'],
      (e['published']['\$t'] as String).substring(0, 10),
    );
  }

  List<String> get images =>
      RegExp(r'<img[^>]+src="([^"]+)"').allMatches(html).map((m) => m.group(1)!).toList();

  String get text => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>|</div>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();
}

Future<List<Post>> fetchPosts(String label) async {
  final path = label == labels[0]
      ? '/feeds/posts/default'
      : '/feeds/posts/default/-/${Uri.encodeComponent(label)}';
  final r = await http.get(Uri.parse('$blog$path?alt=json&max-results=30'));
  final j = jsonDecode(utf8.decode(r.bodyBytes));
  final entries = (j['feed']['entry'] ?? []) as List;
  return entries.map((e) => Post.fromJson(e as Map)).toList();
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VDP News BD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
        home: DefaultTabController(
          length: labels.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('VDP News BD'),
              bottom: TabBar(isScrollable: true, tabs: [for (final l in labels) Tab(text: l)]),
            ),
            body: TabBarView(children: [for (final l in labels) FeedList(label: l)]),
          ),
        ),
      );
}

class FeedList extends StatefulWidget {
  final String label;
  const FeedList({super.key, required this.label});
  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> with AutomaticKeepAliveClientMixin {
  late Future<List<Post>> future = fetchPosts(widget.label);
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => future = fetchPosts(widget.label));
        await future;
      },
      child: FutureBuilder<List<Post>>(
        future: future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return ListView(children: const [
              SizedBox(height: 200),
              Center(child: Text('লোড করা যায়নি। নিচে টেনে আবার চেষ্টা করুন।')),
            ]);
          }
          final posts = s.data!;
          if (posts.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 200),
              Center(child: Text('কোনো খবর নেই')),
            ]);
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final p = posts[i];
              final img = p.images.isNotEmpty ? p.images.first : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => DetailPage(post: p))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (img != null)
                      Image.network(img,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(p.date, style: const TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Post post;
  const DetailPage({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('বিস্তারিত')),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          Text(post.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(post.date, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          for (final u in post.images)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.network(u, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          Text(post.text, style: const TextStyle(fontSize: 17, height: 1.6)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('ব্রাউজারে খুলুন'),
            onPressed: () =>
                launchUrl(Uri.parse(post.link), mode: LaunchMode.externalApplication),
          ),
        ]),
      );
}
