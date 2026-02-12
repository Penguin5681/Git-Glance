class UserModel {
  final String login; // Username
  final int id;
  final String avatarUrl;
  final String htmlUrl;
  final String bio;
  final int followers;
  final int following;
  final int publicRepos;
  final String? company;
  final String? location;
  final String? blog;
  final DateTime? createdAt;
  final String? twitterUsername;

  UserModel({
    required this.login,
    required this.id,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.bio,
    required this.followers,
    required this.following,
    required this.publicRepos,
    this.company,
    this.location,
    this.blog,
    this.createdAt,
    this.twitterUsername,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      login: json['login'] ?? '',
      id: json['id'] ?? 0,
      avatarUrl: json['avatar_url'] ?? '',
      htmlUrl: json['html_url'] ?? '',
      bio: json['bio'] ?? '',
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      publicRepos: json['public_repos'] ?? 0,
      company: json['company'],
      location: json['location'],
      blog: json['blog'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      twitterUsername: json['twitter_username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'id': id,
      'avatar_url': avatarUrl,
      'html_url': htmlUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'public_repos': publicRepos,
      'company': company,
      'location': location,
      'blog': blog,
      'created_at': createdAt?.toIso8601String(),
      'twitter_username': twitterUsername,
    };
  }
}
