import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_chart.dart';
import '../../../providers/user_provider.dart';

class UserLanguageStats extends ConsumerWidget {
  final String username;

  const UserLanguageStats({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse the existing repos provider.
    // This implicitly depends on repos being fetched.
    final reposAsync = ref.watch(userReposProvider(username));

    return reposAsync.when(
      data: (repos) {
         if (repos.isEmpty) return const SizedBox.shrink();
         return LanguageChart(repos: repos);
      },
      loading: () => const SizedBox.shrink(), // Don't show anything while loading chart data to avoid jumping
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
