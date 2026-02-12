import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../data/models/event_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/user_provider.dart';
import 'widgets/user_profile_header.dart';

import 'widgets/repository_list.dart';
import 'settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        ref.read(searchQueryProvider.notifier).state = query;
      } else {
        setState(() {
          _isSearching = false;
        });
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
    });
     FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final bookmarkedUsers = ref.watch(bookmarkServiceProvider);
    final selectedUser = ref.watch(selectedUserProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    // We need to fetch full User Profile data if a user is selected to show detailed header
    // Using AsyncValue to handle loading state
    final selectedUserProfileAsync = selectedUser != null
        ? ref.watch(userProfileProvider(selectedUser))
        : const AsyncValue<UserModel?>.data(null);


    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                AppConstants.appName,
                style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
              floating: true,
              snap: true,
              pinned: false, // Hides when scrolling down
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search GitHub users...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _stopSearching,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
            ),
            // Bookmarked Users List (SliverAdapter)
            if (!_isSearching && bookmarkedUsers.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110, // Slightly increased height to avoid overflows
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    itemCount: bookmarkedUsers.length,
                    itemBuilder: (context, index) {
                      final username = bookmarkedUsers[index];
                      final isSelected = username == selectedUser;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(selectedUserProvider.notifier).state = username;
                          },
                          onLongPress: () {
                            _showRemoveDialog(context, username, ref);
                          },
                          child: ConstrainedBox( // Constraint width to avoid RenderFlex
                            constraints: const BoxConstraints(maxWidth: 70),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserAvatar(username: username, radius: 28),
                                ),
                                const SizedBox(height: 4),
                                Flexible( // Use Flexible/Expanded for text
                                  child: Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ];
        },
        body: _isSearching
            ? _buildSearchResults(searchResultsAsync, ref)
            : _buildMainContent(selectedUser, selectedUserProfileAsync, ref),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<UserModel>> searchResultsAsync, WidgetRef ref) {
    return searchResultsAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isBookmarked = ref.watch(bookmarkServiceProvider).contains(user.login);
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
              title: Text(user.login),
              trailing: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () {
                  ref.read(bookmarkServiceProvider.notifier).toggleBookmark(user.login);
                },
              ),
              onTap: () {
                // When tapping a user from search:
                // 1. Bookmark them (optional, but good UX flow: maybe just select?)
                // Actually, user requirement: "Bookmark (save) ... so I don't have to search... Multi-User Dashboard displays bookmarked."
                // So clicking usually just previews? Or bookmarks?
                // Let's prompt or just toggle. The button is for bookmarking.
                // Tapping could select them and clear search to show profile.
                ref.read(bookmarkServiceProvider.notifier).toggleBookmark(user.login);
                if (!ref.read(bookmarkServiceProvider).contains(user.login)) {
                    // if it was already bookmark and we toggled, it's removed.
                    // re-add if we want to force select?
                    ref.read(bookmarkServiceProvider.notifier).toggleBookmark(user.login);
                }

                ref.read(selectedUserProvider.notifier).state = user.login;
                _stopSearching();
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildMainContent(
      String? selectedUser, AsyncValue<UserModel?> profileAsync, WidgetRef ref) {
    if (ref.watch(bookmarkServiceProvider).isEmpty) {
       return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Search for a user and bookmark them to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
    }

    if (selectedUser == null) {
      return const Center(child: Text('Select a user to view activity'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (selectedUser != null) {
          // Force refresh providers and wait for completion
          try {
             await Future.wait([
               ref.refresh(userProfileProvider(selectedUser).future),
               ref.refresh(userActivityProvider.future),
               ref.refresh(userReposProvider(selectedUser).future),
             ]);
          } catch (e) {
            // Ignore errors during refresh to allow indicator to dismiss
            debugPrint('Error refreshing: $e');
          }
        }
      },
      child: SingleChildScrollView(
         physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Detailed Profile Header
              profileAsync.when(
                  data: (user) => user != null ? UserProfileHeader(user: user) : const SizedBox(),
                  loading: () => const LinearProgressIndicator(),
                  error: (_,__) => const SizedBox(),
              ),
              const Divider(),

               // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "Activity"),
                    Tab(text: "Repositories"),
                  ],
                ),
              ),

               AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                   if (_tabController.index == 0) {
                     return const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: ActivityFeed(),
                     );
                   } else {
                     return Padding(
                       padding: const EdgeInsets.only(top: 10),
                       child: RepositoryList(username: selectedUser),
                     );
                   }
                },
              ),
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, String username, WidgetRef ref) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookmarkServiceProvider.notifier).toggleBookmark(username);
              if (ref.read(selectedUserProvider) == username) {
                ref.read(selectedUserProvider.notifier).state = null;
              }
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends ConsumerWidget {
  final String username;
  final double radius;

  const UserAvatar({super.key, required this.username, required this.radius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProfileProvider(username));

    return userAsyncValue.when(
      data: (user) {
        if (user == null) {
          return CircleAvatar(radius: radius, child: const Icon(Icons.error));
        }
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(user.avatarUrl),
          backgroundColor: Colors.grey.shade800,
        );
      },
      loading: () => CircleAvatar(radius: radius, child: const SizedBox()),
      error: (_, __) => CircleAvatar(radius: radius, child: const Icon(Icons.error)),
    );
  }
}

class ActivityFeed extends ConsumerWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsyncValue = ref.watch(userActivityProvider);

    return activityAsyncValue.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No recent public activity found.'),
          ));
        }
        return ListView.separated(
          shrinkWrap: true, // Important inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Scroll with parent
          itemCount: events.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(event: event);
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

class EventCard extends StatefulWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isExpanded = false;
  // ...existing code to map colors/icons...
  Color _getEventColor(String type) {
     // ...existing code...
     switch (type) {
      case 'PushEvent':
        return AppTheme.eventPush;
      case 'PullRequestEvent':
        return AppTheme.eventPullRequest;
      case 'IssuesEvent':
        return AppTheme.eventIssue;
      default:
        return AppTheme.eventOther;
    }
  }

  IconData _getEventIcon(String type) {
    // ...existing code...
    switch (type) {
      case 'PushEvent':
        return Icons.commit;
      case 'PullRequestEvent':
        return Icons.merge_type;
      case 'IssuesEvent':
        return Icons.bug_report;
      case 'WatchEvent':
        return Icons.star;
      case 'ForkEvent':
        return Icons.call_split;
      default:
        return Icons.info_outline;
    }
  }

  // Helper to build details widget
  Widget _buildDetails(BuildContext context) {
    final payload = widget.event.payload;
    if (widget.event.type == 'PushEvent') {
       final commits = payload['commits'] as List?;
       if (commits == null || commits.isEmpty) return const SizedBox.shrink();
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Divider(),
            const Text('Commits:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ...commits.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                '- ${c['message'] ?? 'No message'}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                 maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            )),
         ],
       );
    } else if (widget.event.type == 'PullRequestEvent') {
       final pr = payload['pull_request'];
       if (pr == null) return const SizedBox.shrink();
       return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Divider(),
             Text(pr['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
             if (pr['body'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  (pr['body'] as String).take(100),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                )
             ]
          ],
       );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getEventColor(widget.event.type).withValues(alpha: 0.2),
              child: Icon(_getEventIcon(widget.event.type), color: _getEventColor(widget.event.type)),
            ),
            title: Text(
              widget.event.description,
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  widget.event.repoName,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().add_jms().format(widget.event.createdAt.toLocal()),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            trailing: IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                    setState(() {
                        _isExpanded = !_isExpanded;
                    });
                },
            ),
            onTap: () {
                 setState(() {
                    _isExpanded = !_isExpanded;
                 });
            },
          ),
          if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      _buildDetails(context),
                      const SizedBox(height: 12),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: () async {
                                  // Open URL
                                  if (widget.event.repoName.isNotEmpty && widget.event.repoName.contains('/')) {
                                      final url = Uri.parse('https://github.com/${widget.event.repoName}');
                                      try {
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      } catch (e) {
                                        // Ignore
                                      }
                                  }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open Repo'),
                          ),
                      )
                  ],
                ),
              )
        ],
      ),
    );
  }
}

extension StringPreview on String {
   String take(int n) {
      if (length <= n) return this;
      return substring(0, n) + '...';
   }
}
