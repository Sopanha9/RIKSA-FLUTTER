/// Blog data models for the Riksa API. See docs/BLOG_API.md.
library;

enum BlogStatus {
  pending,
  approved,
  rejected;

  String get wire => name.toUpperCase();

  static BlogStatus fromWire(String? value) => BlogStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => BlogStatus.pending,
  );
}

class BlogPost {
  BlogPost({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    this.coverUrl,
    required this.status,
    this.rejectionReason,
    required this.viewCount,
    required this.likeCount,
    required this.categoryId,
    required this.liked,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String title;
  final String content;
  final String? coverUrl;
  final BlogStatus status;
  final String? rejectionReason;
  final int viewCount;
  final int likeCount;
  final String categoryId;
  final bool liked;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// Article body prepared for markdown rendering.
  String get markdownContent => normalizeBlogMarkdown(content);

  /// Flattened body used for timeline previews.
  String get plainTextPreview => blogMarkdownPreview(content);

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
    id: json['id']?.toString() ?? '',
    authorId: json['authorId']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    coverUrl: json['coverUrl'] as String?,
    status: BlogStatus.fromWire(json['status'] as String?),
    rejectionReason: json['rejectionReason'] as String?,
    viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    categoryId: json['categoryId']?.toString() ?? '',
    liked: json['liked'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}

/// Paginated list wrapper (`BlogListResponse`). Pages are 0-based.
class BlogPage {
  BlogPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<BlogPost> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory BlogPage.fromJson(Map<String, dynamic> json) => BlogPage(
    content: ((json['content'] as List?) ?? [])
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 0,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

/// Body for both `POST /blog` (create) and `PUT /blog/{id}` (author edit).
class BlogPostRequest {
  BlogPostRequest({
    required this.title,
    required this.content,
    this.coverUrl,
    required this.categoryId,
  });

  final String title;
  final String content;
  final String? coverUrl;
  final String categoryId;

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    if (coverUrl != null) 'coverUrl': coverUrl,
    'categoryId': categoryId,
  };
}

/// Category served over GraphQL (`POST /graphql`).
class BlogCategory {
  BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    required this.memberCount,
    required this.joined,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int memberCount;
  final bool joined;

  factory BlogCategory.fromJson(Map<String, dynamic> json) => BlogCategory(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    iconUrl: json['iconUrl'] as String?,
    memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    joined: json['joined'] as bool? ?? false,
  );
}

/// Unescapes literal `\n` sequences some editors submit as plain text.
String normalizeBlogMarkdown(String value) => value
    .replaceAll(r'\r\n', '\n')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\t', '\t');

/// Strips the markdown syntax that reads badly inside a one-line preview.
String blogMarkdownPreview(String value) => normalizeBlogMarkdown(value)
    .replaceAll(RegExp(r'^[ \t]{0,3}#{1,6}[ \t]+', multiLine: true), '')
    .replaceAll(RegExp(r'^[ \t]*[-+][ \t]+', multiLine: true), '\u2022 ')
    .replaceAll('**', '')
    .replaceAll('__', '')
    .replaceAll('`', '')
    .trim();
