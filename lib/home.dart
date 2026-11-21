import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

const sectionRed = Color(0xFFE02020);
const sections = ['VDP News', 'Ansar VDP News', 'Head Quarter News', 'AVUB News'];

void openCategory(BuildContext c, String label) => Navigator.push(
    c,
    MaterialPageRoute(
        builder: (_) => Scaffold(appBar: topBar(label), body: FeedView(label: label, hero: false))));

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Key refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async {
          setState(() => refreshKey = UniqueKey());
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          key: refreshKey,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          children: [
            const NewsSlider(),
            for (final c in sections) CatSection(label: c),
          ],
        ),
      );
}

class NewsSlider extends StatefulWidget {
  const NewsSlider({super.key});
  @override
  State<NewsSlider> createState() => _NewsSliderState();
}

class _NewsSliderState extends State<NewsSlider> {
  final pc = PageController(viewportFraction: 0.94);
  late final Future<List<Post>> future =
      fetchPosts().then((l) => l.where((p) => p.image != null).take(6).toList());
  int page = 0;
  int count = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!pc.hasClients || count < 2) return;
      pc.animateToPage((page + 1) % count,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Post>>(
        future: future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
          }
          if (s.hasError || s.data == null || s.data!.isEmpty) return const SizedBox.shrink();
          final posts = s.data!;
          count = posts.length;
          return Column(children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: pc,
                itemCount: posts.length,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SlideCard(post: posts[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < posts.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == page ? green : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
          ]);
        },
      );
}

class SlideCard extends StatelessWidget {
  final Post post;
  const SlideCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => openPost(context, post),
          child: Stack(children: [
            Positioned.fill(child: thumb(post.image, h: 250)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(top: 10, left: 10, child: CatChip(post.catName)),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Text(post.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      );
}

class CatSection extends StatefulWidget {
  final String label;
  const CatSection({super.key, required this.label});
  @override
  State<CatSection> createState() => _CatSectionState();
}

class _CatSectionState extends State<CatSection> {
  late final Future<List<Post>> future = fetchPosts(widget.label);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Post>>(
        future: future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Padding(
                padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          }
          if (s.hasError || s.data == null || s.data!.isEmpty) return const SizedBox.shrink();
          final posts = s.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => openCategory(context, widget.label),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
                child: Row(children: [
                  Container(width: 4, height: 24, color: sectionRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.label,
                        style: const TextStyle(
                            color: sectionRed, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.chevron_right, color: sectionRed, size: 32),
                ]),
              ),
            ),
            HeroCard(post: posts.first),
            if (posts.length > 1)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: MiniCard(post: posts[1])),
                const SizedBox(width: 10),
                Expanded(
                    child: posts.length > 2 ? MiniCard(post: posts[2]) : const SizedBox.shrink()),
              ]),
            for (final p in posts.skip(3).take(2)) NewsCard(post: p),
          ]);
        },
      );
}

class MiniCard extends StatelessWidget {
  final Post post;
  const MiniCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => openPost(context, post),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            thumb(post.image, h: 110),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(post.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      );
}
