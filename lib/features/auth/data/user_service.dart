import 'dart:convert';
import '../../../core/api_client.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    this.name = '',
    this.bio = '',
    this.title = '',
    this.location = '',
    this.avatarUrl = '',
    this.phone = '',
    this.linkedinUrl = '',
    this.githubUrl = '',
    this.websiteUrl = '',
    this.portfolioShareToken = '',
    this.createdAt,
  });

  final String id; // String para compatibilidad con Firebase (puede ser string o int convertido)
  final String email;
  final String name;
  final String bio;
  final String title;
  final String location;
  final String avatarUrl;
  final String phone;
  final String linkedinUrl;
  final String githubUrl;
  final String websiteUrl;
  final String portfolioShareToken;
  final String? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '', // Convertir int o string a string
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        title: json['title'] as String? ?? '',
        location: json['location'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        linkedinUrl: json['linkedin_url'] as String? ?? '',
        githubUrl: json['github_url'] as String? ?? '',
        websiteUrl: json['website_url'] as String? ?? '',
        portfolioShareToken: json['portfolio_share_token'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'bio': bio,
        'title': title,
        'location': location,
        'avatar_url': avatarUrl,
        'phone': phone,
        'linkedin_url': linkedinUrl,
        'github_url': githubUrl,
        'website_url': websiteUrl,
      };
}

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<UserProfile> getProfile() async {
    final r = await _api.get('/api/users/me');
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final r = await _api.put('/api/users/me', body: profile.toJson());
    final json = jsonDecode(r.body) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }
}
