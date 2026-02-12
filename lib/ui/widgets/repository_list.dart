import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/repository_model.dart';
import '../../providers/user_provider.dart';

class RepositoryList extends ConsumerWidget {
  final String username;

  const RepositoryList({super.key, required this.username});

  Color _getLanguageColor(String language) {
    // Basic hash to get a consistent color
    final int hash = language.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.amber, Colors.indigo
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.watch(userReposProvider(username));

    return reposAsync.when(
      data: (repos) {
        if (repos.isEmpty) {
          return const Center(child: Text('No repositories found.'));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: repos.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final repo = repos[index];
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
                      Text(
                        repo.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

