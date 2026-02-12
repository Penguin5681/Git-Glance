import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/repository_model.dart';
import '../../providers/user_provider.dart';

class RepositoryList extends ConsumerStatefulWidget {
  final String username;
  const RepositoryList({super.key, required this.username});
  @override
  ConsumerState<RepositoryList> createState() => _RepositoryListState();
}

class _RepositoryListState extends ConsumerState<RepositoryList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getLanguageColor(String language) {
    // Basic hash to get a consistent color
    final int hash = language.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.amber, Colors.indigo
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final reposAsync = ref.watch(userReposProvider(widget.username));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Filter repositories...',
              prefixIcon: const Icon(Icons.filter_list),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) {
               setState(() {
                 _searchQuery = val.toLowerCase();
               });
            },
          ),
        ),
        reposAsync.when(
          data: (repos) {
            final filteredRepos = repos.where((repo) {
              return repo.name.toLowerCase().contains(_searchQuery) ||
                     (repo.language?.toLowerCase().contains(_searchQuery) ?? false);
            }).toList();

            if (filteredRepos.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No repositories match filter.'),
              ));
            }
            return ListView.builder( // Was separated but now inside Column/List ok? No.
              // RepositoryList is inside a Column inside RefreshIndicator -> SingleChildScrollView in HomePage.
              // So ListView here must be shrinkWrap: true physics: NeverScrollable.
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRepos.length,
              itemBuilder: (context, index) {
                final repo = filteredRepos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  repo.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (repo.description != null && repo.description!.isNotEmpty) ...[
                             const SizedBox(height: 8),
                             Text(
                              repo.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Language
                              if (repo.language != null) ...[
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: _getLanguageColor(repo.language!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(repo.language!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(width: 16),
                              ],
                              // Stars
                              Icon(Icons.star_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('${repo.stargazersCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(width: 16),
                               // Forks
                              Icon(Icons.fork_right, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('${repo.forksCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),

                              const Spacer(),
                              // Update date
                              Text(
                                DateFormat.MMMd().format(repo.updatedAt.toLocal()),
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, stack) => Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $err'),
          )),
        ),
      ],
    );
  }
}
