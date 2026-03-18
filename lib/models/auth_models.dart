import 'dart:convert';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
    this.email,
  });

  final int id;
  final String username;
  final String role;
  final String? email;

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'email': email,
      };
}

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory SessionTokens.fromJson(Map<String, dynamic> json) {
    return SessionTokens(
      accessToken: json['access_token'] as String? ?? json['accessToken'] as String? ?? '',
      refreshToken:
          json['refresh_token'] as String? ?? json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

  String encode() => jsonEncode(toJson());

  static SessionTokens decode(String raw) =>
      SessionTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class SavedAccount {
  const SavedAccount({
    required this.serverUrl,
    required this.username,
    required this.scopeKey,
    required this.lastUsedAt,
    this.userId,
    this.role,
  });

  final String serverUrl;
  final String username;
  final String scopeKey;
  final DateTime lastUsedAt;
  final int? userId;
  final String? role;

  String get hostLabel => Uri.tryParse(serverUrl)?.host ?? serverUrl;

  String get title => '$username @ $hostLabel';

  factory SavedAccount.create({
    required String serverUrl,
    required String username,
    int? userId,
    String? role,
    DateTime? lastUsedAt,
  }) {
    final normalizedUrl = normalizeServerUrl(serverUrl);
    final cleanUsername = username.trim();
    return SavedAccount(
      serverUrl: normalizedUrl,
      username: cleanUsername,
      scopeKey: scopeFor(normalizedUrl, cleanUsername),
      userId: userId,
      role: role,
      lastUsedAt: lastUsedAt ?? DateTime.now(),
    );
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    final serverUrl = json['serverUrl'] as String? ?? '';
    final username = json['username'] as String? ?? '';
    return SavedAccount(
      serverUrl: serverUrl,
      username: username,
      scopeKey: json['scopeKey'] as String? ?? scopeFor(serverUrl, username),
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ?? DateTime.now(),
      userId: (json['userId'] as num?)?.toInt(),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'scopeKey': scopeKey,
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'userId': userId,
        'role': role,
      };

  SavedAccount copyWith({
    String? serverUrl,
    String? username,
    String? scopeKey,
    DateTime? lastUsedAt,
    int? userId,
    String? role,
  }) {
    return SavedAccount(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      scopeKey: scopeKey ?? this.scopeKey,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }

  static String scopeFor(String serverUrl, String username) {
    final uri = Uri.tryParse(serverUrl);
    final authority = uri?.authority.isNotEmpty == true ? uri!.authority : serverUrl;
    final normalizedAuthority = authority.toLowerCase().replaceAll(RegExp(r'[^a-z0-9:_-]'), '_');
    final normalizedUser = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return '${normalizedAuthority}_$normalizedUser';
  }
}

class AuthSession {
  const AuthSession({
    required this.account,
    required this.tokens,
    required this.user,
  });

  final SavedAccount account;
  final SessionTokens tokens;
  final UserProfile user;

  AuthSession copyWith({
    SavedAccount? account,
    SessionTokens? tokens,
    UserProfile? user,
  }) {
    return AuthSession(
      account: account ?? this.account,
      tokens: tokens ?? this.tokens,
      user: user ?? this.user,
    );
  }
}

class ServerCapabilities {
  const ServerCapabilities({
    required this.authRequired,
    required this.localEnabled,
    required this.oidcEnabled,
    this.oidcLabel,
  });

  final bool authRequired;
  final bool localEnabled;
  final bool oidcEnabled;
  final String? oidcLabel;

  factory ServerCapabilities.fromJson(Map<String, dynamic> json) {
    final local = (json['local'] as Map<String, dynamic>?) ?? const {};
    final oidc = (json['oidc'] as Map<String, dynamic>?) ?? const {};
    return ServerCapabilities(
      authRequired: json['auth_required'] as bool? ?? false,
      localEnabled: local['enabled'] as bool? ?? false,
      oidcEnabled: oidc['enabled'] as bool? ?? false,
      oidcLabel: oidc['label'] as String?,
    );
  }
}

class SessionEnvelope {
  const SessionEnvelope({
    required this.tokens,
    required this.user,
  });

  final SessionTokens tokens;
  final UserProfile user;

  factory SessionEnvelope.fromJson(Map<String, dynamic> json) {
    return SessionEnvelope(
      tokens: SessionTokens.fromJson(json),
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

String normalizeServerUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Server URL is required.');
  }
  final withScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'http://$trimmed';
  final parsed = Uri.parse(withScheme);
  final sanitized = parsed.replace(path: parsed.path == '/' ? '' : parsed.path).toString();
  return sanitized.endsWith('/') ? sanitized.substring(0, sanitized.length - 1) : sanitized;
}
