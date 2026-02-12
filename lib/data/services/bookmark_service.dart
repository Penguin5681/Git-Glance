import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'github_service.dart';
import 'storage_service.dart';

class BookmarkService extends StateNotifier<List<String>> {
  final StorageService _storageService;
  final GitHubService _githubService;

  BookmarkService(this._storageService, this._githubService)
      : super(_storageService.getBookmarkedUsers());

  // Search for a user
  Future<UserModel?> searchUser(String username) async {
    try {
      return await _githubService.getUser(username);
    } catch (e) {
      // Handle error gracefully
      return null;
    }
  }

  // Toggle bookmark (add/remove)
  Future<void> toggleBookmark(String username) async {
    if (state.contains(username)) {
      state = state.where((u) => u != username).toList();
    } else {
      state = [...state, username];
    }
    await _storageService.saveBookmarkedUsers(state);
  }

  bool isBookmarked(String username) {
    return state.contains(username);
  }
}

