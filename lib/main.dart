
Widget drawerCat(BuildContext context, String label) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 20)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => Scaffold(
                    appBar: topBar(label), body: FeedView(label: label, hero: false))));
      },
    );

Widget drawerLink(String t, String url, {bool sub = false}) => ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: sub ? 38 : 22),
      title: Text(t, style: TextStyle(color: Colors.white, fontSize: sub ? 17 : 20)),
      trailing: const Icon(Icons.open_in_new, color: green, size: 18),
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  Widget group(String title, List<Widget> kids) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: green,
          collapsedIconColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 22),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
          children: kids,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: topBar(null),
        drawer: Drawer(
          backgroundColor: const Color(0xFF2B2B2B),
          shape: const RoundedRectangleBorder(),
          child: ListView(padding: EdgeInsets.zero, children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              child: const Text.rich(TextSpan(children: [
                TextSpan(text: 'VDP ', style: TextStyle(color: Color(0xFFE02020))),
                TextSpan(text: 'News BD', style: TextStyle(color: green)),
              ], style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900))),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(18),
              child: const Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 22),
              title: const Text('Home', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.pop(context);
                setState(() => tab = 0);
              },
            ),
            drawerCat(context, 'VDP News'),
            drawerCat(context, 'Ansar VDP News'),
            drawerCat(context, 'Head Quarter News'),
            drawerCat(context, 'AVUB News'),
            drawerLink('History', '$blog/p/blog-page.html'),
            group('More', [
              drawerLink('Director General', '$blog/p/blog-page_24.html', sub: true),
              drawerLink('AVUB Website', 'https://ansarvdpbank.portal.gov.bd/', sub: true),
              drawerLink('Notice Board', 'https://ansarvdpbank.portal.gov.bd/site/view/notices', sub: true),
              drawerLink('Job Circular', 'https://pickdejob.blogspot.com/', sub: true),
            ]),
            group('Shukhee Insurance Service', [
              drawerLink('Shukhee Apps Registration & Log In', 'https://www.shukhee.com/', sub: true),
              drawerLink('Shukhee Apps Download', 'https://shukhee.com/app/download', sub: true),
            ]),
            group('Learn More', [
              drawerLink('Disclaimer', '$blog/p/disclaimer-for-vdpnewsblogspotcom.html', sub: true),
              drawerLink('Privacy Policy', '$blog/p/privacy-policy-for-vdpnews.html', sub: true),
              drawerLink('Comment Policy', '$blog/p/comment-policy.html', sub: true),
              drawerLink('Contact Us', '$blog/p/contact-us.html', sub: true),
            ]),
          ]),
        ),
        body: IndexedStack(index: tab, children: const [
          FeedView(hero: true),
          FeedView(hero: false),
          FavView(),
        ]),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'হোম'),
            NavigationDestination(icon: Icon(Icons.access_time), selectedIcon: Icon(Icons.access_time_filled), label: 'সর্বশেষ'),
            NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'ফেভারিট'),
          ],
        ),
      );
}
EOF>>
cat >> lib/main.dart << 'EOF'

class FeedView extends StatefulWidget {
  final String? label;
  final bool hero;
  const FeedView({super.key, this.label, required this.hero});
  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late Future<List<Post>> future = fetchPosts(widget.label);

  @override
  Widget build(BuildContext context) => RefreshIndicator(
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
              padding: const EdgeInsets.all(10),
              itemCount: posts.length,
              itemBuilder: (_, i) =>
                  (widget.hero && i == 0) ? HeroCard(post: posts[i]) : NewsCard(post: posts[i]),
            );
          },
        ),
      );
}

void openPost(BuildContext c, Post p) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => DetailPage(post: p)));

class CatChip extends StatelessWidget {
  final String text;
  const CatChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5DB85C), Color(0xFF14A08A)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      );
}

class TimeRow extends StatelessWidget {
  final Post post;
  const TimeRow(this.post, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.access_time_filled, size: 20, color: Color(0xFF333A4A)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(ago(post.date),
                style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis)),
        CatChip(post.catName),
      ]);
}

Widget thumb(String? url, {double? h}) => url == null
    ? Container(height: h, color: Colors.grey.shade300, child: const Icon(Icons.image, color: Colors.grey, size: 40))
    : Image.network(url,
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(height: h, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, color: Colors.grey)));

class HeroCard extends StatelessWidget {
  final Post post;
  const HeroCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => openPost(context, post),
          child: Column(children: [
            Stack(children: [
              thumb(post.image, h: 260),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                      stops: const [0.4, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Text(post.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)),
              ),
            ]),
            Padding(padding: const EdgeInsets.all(12), child: TimeRow(post)),
          ]),
        ),
      );
}

class NewsCard extends StatelessWidget {
  final Post post;
  const NewsCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => openPost(context, post),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: 140, child: thumb(post.image)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TimeRow(post),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

class FavView extends StatelessWidget {
  const FavView({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<Post>>(
        valueListenable: Favs.list,
        builder: (_, l, __) => l.isEmpty
            ? const Center(child: Text('কোনো ফেভারিট খবর নেই'))
            : ListView(
                padding: const EdgeInsets.all(10),
                children: [for (final p in l) NewsCard(post: p)]),
      );
}

class DetailPage extends StatelessWidget {
  final Post post;
  const DetailPage({super.key, required this.post});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('বিস্তারিত'),
          actions: [
            ValueListenableBuilder<List<Post>>(
              valueListenable: Favs.list,
              builder: (_, __, ___) => IconButton(
                icon: Icon(Favs.has(post) ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => Favs.toggle(post),
              ),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TimeRow(post),
          const SizedBox(height: 12),
          for (final u in post.images)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.network(u, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          Text(post.text, style: const TextStyle(fontSize: 18, height: 1.65)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('ব্রাউজারে খুলুন'),
            onPressed: () => launchUrl(Uri.parse(post.link), mode: LaunchMode.externalApplication),
          ),
        ]),
      );
}
