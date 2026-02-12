import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveBookmarkedUsers(List<String> usernames) async {
    await _prefs.setStringList(AppConstants.bookmarkedUsersKey, usernames);
  }

  List<String> getBookmarkedUsers() {
    return _prefs.getStringList(AppConstants.bookmarkedUsersKey) ?? [];
  }

  Future<void> saveApiToken(String token) async {
    await _prefs.setString(AppConstants.apiTokenKey, token);
  }

  String? getApiToken() {
    return _prefs.getString(AppConstants.apiTokenKey);
  }
}
