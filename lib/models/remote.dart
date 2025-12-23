class Remote {
  final int? id;
  final String name;
  final String createdAt;

  Remote({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  factory Remote.fromMap(Map<String, dynamic> map) {
    return Remote(
      id: map['id'],
      name: map['name'],
      createdAt: map['created_at'],
    );
  }
}
