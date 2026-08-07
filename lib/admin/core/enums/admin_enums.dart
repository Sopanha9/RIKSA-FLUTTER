import 'package:json_annotation/json_annotation.dart';

enum Role {
  @JsonValue('USER')
  user,
  @JsonValue('MODERATOR')
  moderator,
  @JsonValue('ADMIN')
  admin;

  String get label => switch (this) {
    Role.user => 'User',
    Role.moderator => 'Moderator',
    Role.admin => 'Admin',
  };
}

enum DifficultyLevel {
  @JsonValue('EASY')
  easy,
  @JsonValue('MEDIUM')
  medium,
  @JsonValue('HARD')
  hard,
  @JsonValue('DIFFICULT')
  difficult;
}

enum ContentStatus {
  @JsonValue('VISIBLE')
  visible,
  @JsonValue('HIDDEN')
  hidden;
}

enum BlogStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected;
}

enum ReportStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('RESOLVED')
  resolved,
  @JsonValue('DISMISSED')
  dismissed;
}

enum ReportAction {
  @JsonValue('NONE')
  none,
  @JsonValue('HIDE')
  hide;
}

enum ReportTargetType {
  @JsonValue('POST')
  post,
  @JsonValue('COMMENT')
  comment,
  @JsonValue('BLOG')
  blog;
}

enum ReportReason {
  @JsonValue('SPAM')
  spam,
  @JsonValue('HARASSMENT')
  harassment,
  @JsonValue('NSFW')
  nsfw,
  @JsonValue('MISINFORMATION')
  misinformation,
  @JsonValue('OTHER')
  other;
}