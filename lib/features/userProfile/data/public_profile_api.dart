import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import 'public_profile.dart';

abstract interface class PublicProfileRepository {
  Future<PublicProfile> fetch(String userId);
}

class HttpPublicProfileRepository implements PublicProfileRepository {
  HttpPublicProfileRepository(this._client);

  final DioClient _client;

  @override
  Future<PublicProfile> fetch(String userId) async {
    try {
      final response = await _client.dio.get(
        '/profiles/${Uri.encodeComponent(userId)}',
      );
      return PublicProfile.fromJson(jsonMap(response));
    } on DioException catch (error) {
      if (const {403, 404, 410, 423}.contains(error.response?.statusCode)) {
        throw const PublicProfileUnavailableException();
      }
      rethrow;
    }
  }
}

class PublicProfileUnavailableException implements Exception {
  const PublicProfileUnavailableException();
}

abstract interface class PublicProfileSocialRepository {
  Future<SocialFeedPage> feed({
    required String authorId,
    String? cursor,
    required int limit,
  });

  Future<SocialPost> react(String postId);

  Future<SocialPost> share(String postId);
}

class SocialApiPublicProfileRepository
    implements PublicProfileSocialRepository {
  SocialApiPublicProfileRepository(this._api);

  final SocialApi _api;

  @override
  Future<SocialFeedPage> feed({
    required String authorId,
    String? cursor,
    required int limit,
  }) => _api.feed(authorId: authorId, cursor: cursor, limit: limit);

  @override
  Future<SocialPost> react(String postId) =>
      _api.react(postId: postId, reaction: SocialReaction.upvote);

  @override
  Future<SocialPost> share(String postId) => _api.share(postId);
}
