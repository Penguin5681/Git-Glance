import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/repository_model.dart';
import '../../core/constants.dart';

class GitHubService {
  final http.Client client;
  final String? token;

  GitHubService({http.Client? client, this.token}) : client = client ?? http.Client();

  Map<String, String> get _headers {
    if (token != null && token!.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
      };
    }
    return {
      'Accept': 'application/vnd.github.v3+json',
    };
  }

  Future<UserModel?> getUser(String username) async {
    final url = Uri.parse('${AppConstants.githubApiBaseUrl}/users/$username');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  Future<List<EventModel>> getUserEvents(String username) async {
    final url = Uri.parse('${AppConstants.githubApiBaseUrl}/users/$username/events?per_page=30');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => EventModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final url = Uri.parse('${AppConstants.githubApiBaseUrl}/search/users?q=$query');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> items = body['items'] ?? [];
      return items.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<UserModel?> getAuthenticatedUser() async {
    final url = Uri.parse('${AppConstants.githubApiBaseUrl}/user');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  Future<List<RepositoryModel>> getUserRepos(String username, {bool isCurrentUser = false}) async {
    // If it's the authenticated user, we might want to see private repos.
    // The endpoint /user/repos lists repos the authenticated user has access to (including private, orgs, etc.)
    // But it requires "type" parameter or similar to filter. Default is generic.
    // /users/{username}/repos only lists public unless we own it?
    // According to docs: "GET /users/{username}/repos lists public repositories for the specified user."
    // "To access private repositories, use GET /user/repos."

    final Uri url;
    if (isCurrentUser) {
       url = Uri.parse('${AppConstants.githubApiBaseUrl}/user/repos?sort=updated&per_page=100&type=all');
    } else {
       url = Uri.parse('${AppConstants.githubApiBaseUrl}/users/$username/repos?sort=updated&per_page=100');
    }

    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => RepositoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load repos');
    }
  }

  Future<List<RepositoryModel>> getTrendingRepos() async {
    // Get date 7 days ago
    final date = DateTime.now().subtract(const Duration(days: 7));
    final formattedDate = date.toIso8601String().split('T')[0];

    final url = Uri.parse('${AppConstants.githubApiBaseUrl}/search/repositories?q=created:>$formattedDate&sort=stars&order=desc');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> items = body['items'] ?? [];
      return items.map((e) => RepositoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load trending repos');
    }
  }
}
