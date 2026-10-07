/// Una página de resultados de la API (`Page[T]` en el backend).
///
/// Se llama `PageModel` y no `Page` porque Flutter ya tiene una clase `Page`
/// (las rutas de Navigator) y chocarían en las vistas.
class PageModel<T> {
  final List<T> items;

  /// Total de resultados del filtro, no el tamaño de esta página.
  final int total;
  final int limit;
  final int offset;

  const PageModel({required this.items, required this.total, required this.limit, required this.offset});

  factory PageModel.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromItem) {
    return PageModel(
      items: (json['items'] as List).map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
    );
  }

  /// Si hay más resultados después de esta página.
  bool get hasMore => offset + items.length < total;
}
