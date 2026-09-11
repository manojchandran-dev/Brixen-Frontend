/// A single entry in the app's server-driven navigation menu. Read-only —
/// there's only a GET endpoint for this, since it's static app-level menu
/// metadata rather than per-tenant business data.
class NavModule {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final List<NavModule> children;

  const NavModule({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.children = const [],
  });

  factory NavModule.fromJson(Map<String, dynamic> json) => NavModule(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    description: json['description']?.toString(),
    parentId: json['parent_id']?.toString(),
    children: (json['children'] as List<dynamic>? ?? [])
        .map((c) => NavModule.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
