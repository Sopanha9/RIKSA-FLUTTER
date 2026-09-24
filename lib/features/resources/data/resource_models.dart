library;

enum LessonResourceKind {
  link,
  pdf,
  video;

  static LessonResourceKind fromWire(Object? value) =>
      switch (value?.toString().toUpperCase()) {
        'PDF' => pdf,
        'VIDEO' => video,
        _ => link,
      };

  String get wire => name.toUpperCase();
}

class ResourceAuthor {
  const ResourceAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory ResourceAuthor.fromJson(Map<String, dynamic> json) => ResourceAuthor(
    id: json['id']?.toString() ?? '',
    displayName: json['displayName'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
  );
}

class LessonResource {
  const LessonResource({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.url,
    required this.kind,
    required this.author,
    required this.saveCount,
    required this.savedByMe,
    required this.createdAt,
  });

  final String id;
  final String lessonId;
  final String title;
  final String url;
  final LessonResourceKind kind;
  final ResourceAuthor author;
  final int saveCount;
  final bool savedByMe;
  final DateTime? createdAt;

  String get domain {
    try {
      return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
    } on FormatException {
      return url;
    }
  }

  LessonResource copyWith({int? saveCount, bool? savedByMe}) => LessonResource(
    id: id,
    lessonId: lessonId,
    title: title,
    url: url,
    kind: kind,
    author: author,
    saveCount: saveCount ?? this.saveCount,
    savedByMe: savedByMe ?? this.savedByMe,
    createdAt: createdAt,
  );

  factory LessonResource.fromJson(Map<String, dynamic> json) => LessonResource(
    id: json['id']?.toString() ?? '',
    lessonId: json['lessonId']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    kind: LessonResourceKind.fromWire(json['kind']),
    author: ResourceAuthor.fromJson(
      (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
    savedByMe: json['savedByMe'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class LessonResourcePage {
  const LessonResourcePage({
    required this.edges,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<LessonResource> edges;
  final bool hasNextPage;
  final String? endCursor;

  factory LessonResourcePage.fromJson(Map<String, dynamic> json) =>
      LessonResourcePage(
        edges: ((json['edges'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (value) => LessonResource.fromJson(value.cast<String, dynamic>()),
            )
            .toList(growable: false),
        hasNextPage: json['hasNextPage'] as bool? ?? false,
        endCursor: json['endCursor']?.toString(),
      );
}

class LessonResourcesState {
  const LessonResourcesState({
    required this.resources,
    required this.hasNextPage,
    this.endCursor,
    this.loadingMore = false,
  });

  final List<LessonResource> resources;
  final bool hasNextPage;
  final String? endCursor;
  final bool loadingMore;

  LessonResourcesState append(LessonResourcePage page) => LessonResourcesState(
    resources: [...resources, ...page.edges],
    hasNextPage: page.hasNextPage,
    endCursor: page.endCursor,
  );

  LessonResourcesState prepend(LessonResource resource) => LessonResourcesState(
    resources: [resource, ...resources.where((item) => item.id != resource.id)],
    hasNextPage: hasNextPage,
    endCursor: endCursor,
    loadingMore: loadingMore,
  );
}

abstract final class ResourceShareRules {
  static String? titleError(String value) {
    final length = value.trim().length;
    if (length < 3 || length > 120) return 'title';
    return null;
  }

  static String? urlError(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return 'url';
    }
    return null;
  }
}
