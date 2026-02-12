class EventModel {
  final String id;
  final String type;
  final String repoName;
  final String repoUrl;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  EventModel({
    required this.id,
    required this.type,
    required this.repoName,
    required this.repoUrl,
    required this.createdAt,
    required this.payload,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'UnknownEvent',
      repoName: json['repo']?['name'] ?? 'Unknown Repo',
      repoUrl: json['repo']?['url'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      payload: json['payload'] ?? {},
    );
  }

  // Helper method to get a user friendly description
  String get description {
    switch (type) {
      case 'PushEvent':
        final size = payload['size'];
        // If distinct size is provided and > 0, use it
        if (size != null && size is int && size > 0) {
          return 'Pushed $size commit${size == 1 ? '' : 's'}';
        }

        final commits = payload['commits'] as List?;
        final count = commits?.length ?? 0;

        if (count > 0) {
           return 'Pushed $count commit${count == 1 ? '' : 's'}';
        }

        // Fallback for 0 commits or unknown size (e.g. force push or ref update)
        return 'Pushed code updates';
      case 'PullRequestEvent':
        final action = payload['action'] ?? 'interacted with';
        return '${action.toString().capitalize()} pull request';
      case 'IssuesEvent':
        final action = payload['action'] ?? 'interacted with';
        return '${action.toString().capitalize()} issue';
      case 'WatchEvent':
        return 'Starred repository';
      case 'ForkEvent':
        return 'Forked repository';
      case 'CreateEvent':
        final refType = payload['ref_type'] ?? 'item';
        return 'Created $refType';
      case 'DeleteEvent':
        final refType = payload['ref_type'] ?? 'item';
        return 'Deleted $refType';
      case 'ReleaseEvent':
        return 'Published a release';
      default:
        return 'Performed $type';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

