import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingReposProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trending Repos', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.refresh(trendingReposProvider.future);
          } catch (e) {
            debugPrint('Error refreshing trending: $e');
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Hot this week',
                 style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          trendingAsync.when(
            data: (repos) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final repo = repos[index];
                  // Reuse the card style from RepositoryList but maybe simpler?
                  // Or let's create a TrendingRepoCard.
                  // For now, consistent style.
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    child: ListTile(
                      title: Text(repo.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (repo.description != null)
                            Text(repo.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                               Icon(Icons.star, size: 16, color: Colors.amber),
                               const SizedBox(width: 4),
                               Text('${repo.stargazersCount}'),
                               const SizedBox(width: 16),
                               if (repo.language != null) ...[
                                 Text(repo.language!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                               ]
                            ],
                          )
                        ],
                      ),
                      onTap: () async {
                         final url = Uri.parse(repo.htmlUrl);
                         try {
                           if (await canLaunchUrl(url)) {
                             await launchUrl(url, mode: LaunchMode.externalApplication);
                           }
                         } catch (e) {
                           // Ignore
                         }
                      },
                    ),
                  );
                },
                childCount: repos.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    ));
  }
}


