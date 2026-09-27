import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/resource_models.dart';
import '../data/resources_api.dart';

final resourcesRepositoryProvider = Provider<ResourcesRepository>((ref) {
  return ResourcesApi(ref.watch(dioClientProvider));
});

class LessonResourcesNotifier extends AsyncNotifier<LessonResourcesState> {
  LessonResourcesNotifier(this.lessonId);

  final String lessonId;
  int _requestVersion = 0;

  @override
  Future<LessonResourcesState> build() async {
    watchCurrentUserId(ref);
    _requestVersion++;
    final page = await ref.watch(resourcesRepositoryProvider).list(lessonId);
    return LessonResourcesState(
      resources: page.edges,
      hasNextPage: page.hasNextPage,
      endCursor: page.endCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasNextPage ||
        current.loadingMore ||
        current.endCursor == null) {
      return;
    }
    final requestVersion = _requestVersion;
    state = AsyncData(
      LessonResourcesState(
        resources: current.resources,
        hasNextPage: current.hasNextPage,
        endCursor: current.endCursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(resourcesRepositoryProvider)
          .list(lessonId, cursor: current.endCursor);
      if (requestVersion != _requestVersion) return;
      state = AsyncData(current.append(page));
    } catch (_) {
      if (requestVersion == _requestVersion) state = AsyncData(current);
    }
  }

  Future<LessonResource> create({
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) async {
    final requestVersion = _requestVersion;
    final resource = await ref
        .read(resourcesRepositoryProvider)
        .create(lessonId, title: title, url: url, kind: kind);
    if (requestVersion != _requestVersion) return resource;
    final current = state.value;
    if (current != null) state = AsyncData(current.prepend(resource));
    return resource;
  }

  Future<void> toggleSave(LessonResource resource) async {
    final current = state.value;
    if (current == null) return;
    final requestVersion = _requestVersion;
    final wasSaved = resource.savedByMe;
    state = AsyncData(
      _replaceResource(
        current,
        resource.copyWith(
          savedByMe: !wasSaved,
          saveCount: resource.saveCount + (wasSaved ? -1 : 1),
        ),
      ),
    );
    try {
      final result = wasSaved
          ? await ref.read(resourcesRepositoryProvider).unsave(resource.id)
          : await ref.read(resourcesRepositoryProvider).save(resource.id);
      if (requestVersion != _requestVersion) return;
      final next = state.value ?? current;
      state = AsyncData(_replaceResource(next, result));
      ref.invalidate(profileDashboardProvider);
    } catch (_) {
      if (requestVersion == _requestVersion) state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final requestVersion = _requestVersion;
    await ref.read(resourcesRepositoryProvider).delete(id);
    if (requestVersion != _requestVersion) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      LessonResourcesState(
        resources: current.resources.where((item) => item.id != id).toList(),
        hasNextPage: current.hasNextPage,
        endCursor: current.endCursor,
      ),
    );
  }

  LessonResourcesState _replaceResource(
    LessonResourcesState current,
    LessonResource updated,
  ) => LessonResourcesState(
    resources: current.resources
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false),
    hasNextPage: current.hasNextPage,
    endCursor: current.endCursor,
    loadingMore: current.loadingMore,
  );
}

final lessonResourcesProvider =
    AsyncNotifierProvider.family<
      LessonResourcesNotifier,
      LessonResourcesState,
      String
    >((lessonId) => LessonResourcesNotifier(lessonId));
