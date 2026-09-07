class ServerConnection {
  final String id;
  final String label;
  final String ip;
  final int port;
  final DateTime lastUsedAt;
  final bool isFavorite;

  const ServerConnection({
    required this.id,
    required this.label,
    required this.ip,
    required this.port,
    required this.lastUsedAt,
    this.isFavorite = false,
  });

  String get url => 'http://$ip:$port';
  String get address => '$ip:$port';

  ServerConnection copyWith({
    String? id,
    String? label,
    String? ip,
    int? port,
    DateTime? lastUsedAt,
    bool? isFavorite,
  }) {
    return ServerConnection(
      id: id ?? this.id,
      label: label ?? this.label,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'ip': ip,
      'port': port,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory ServerConnection.fromJson(Map<String, dynamic> json) {
    return ServerConnection(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: json['label'] as String? ?? '',
      ip: json['ip'] as String? ?? '127.0.0.1',
      port: (json['port'] as num?)?.toInt() ?? 3000,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConnection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
