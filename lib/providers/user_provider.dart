import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/event_model.dart';
import '../data/models/user_model.dart';
import '../data/models/repository_model.dart';
import '../data/services/github_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/bookmark_service.dart';

// Services Providers
final storageServiceProvider = Provider<StorageService>((ref) {
  // This will be overridden in main.dart with the initialized instance
  throw UnimplementedError('StorageService not initialized');
});

// API Token Provider
final apiTokenProvider = Provider<String?>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getApiToken();
});

// GitHub Service Provider
final githubServiceProvider = Provider<GitHubService>((ref) {
  final token = ref.watch(apiTokenProvider);
  return GitHubService(token: token);
});

// Bookmark Service Provider (StateNotifier)
// Manages the list of bookmarked usernames
final bookmarkServiceProvider =
    StateNotifierProvider<BookmarkService, List<String>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final githubService = ref.watch(githubServiceProvider);
  return BookmarkService(storageService, githubService);
});

// Provider for fetching user details for a given username
// Used for displaying the user info in the activity feed or bookmarks list
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, username) async {
  final githubService = ref.watch(githubServiceProvider);
  return githubService.getUser(username);
});

// Selected User Provider (which user is currently being viewed)
final selectedUserProvider = StateProvider<String?>((ref) => null);

// Activity Feed Provider for the *selected* user
final userActivityProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final selectedUsername = ref.watch(selectedUserProvider);
  if (selectedUsername == null) {
    return [];
  }
  final githubService = ref.watch(githubServiceProvider);
  try {
    return await githubService.getUserEvents(selectedUsername);
  } catch (e) {
    // Return empty list on error for now, or re-throw to handle in UI
    return [];
  }
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search Results Provider with Debounce
final searchResultsProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final githubService = ref.watch(githubServiceProvider);

  // Return empty stream if query is empty
  if (query.isEmpty) {
    return Stream.value([]);
  }

  // Create stream manually to use Stream-based debounce
  // Using Riverpod's own capabilities, or simply return a FutureProvider and handle debounce in UI?
  // Riverpod doesn't have built-in stream debounce for FutureProvider.
  // We can use a StreamController or rxdart.
  // Actually, since we are using StreamProvider, we need to return a Stream.
  // But a simpler way for "Search" is typically handling the debounce *before* updating the search query provider,
  // OR implementing it here.
  // Let's rely on the UI updating the `searchQueryProvider` with debounce,
  // and this provider just fetching when the query changes.
  return Stream.fromFuture(githubService.searchUsers(query));
});

// Authenticated User Provider
final authenticatedUserProvider = Provider<String?>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAuthenticatedUser();
});

// Update userReposProvider to verify if we are fetching for the logged in user
final userReposProvider = FutureProvider.family<List<RepositoryModel>, String>((ref, username) async {
  final githubService = ref.watch(githubServiceProvider);
  final authUser = ref.watch(authenticatedUserProvider);
  // Check if requested username matches stored authenticated user
  final isCurrentUser = authUser != null && authUser.toLowerCase() == username.toLowerCase();

  return githubService.getUserRepos(username, isCurrentUser: isCurrentUser);
});

// Trending Repositories Provider
final trendingReposProvider = FutureProvider<List<RepositoryModel>>((ref) async {
  final githubService = ref.watch(githubServiceProvider);
  return githubService.getTrendingRepos();
});

