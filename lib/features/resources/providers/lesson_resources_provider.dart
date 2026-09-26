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

  @override
  Future<LessonResourcesState> build() async {
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
      state = AsyncData(current.append(page));
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<LessonResource> create({
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) async {
    final resource = await ref
        .read(resourcesRepositoryProvider)
        .create(lessonId, title: title, url: url, kind: kind);
    final current = state.value;
    if (current != null) state = AsyncData(current.prepend(resource));
    return resource;
  }

  Future<void> toggleSave(LessonResource resource) async {
    final current = state.value;
    if (current == null) return;
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
      final next = state.value ?? current;
      state = AsyncData(_replaceResource(next, result));
      ref.invalidate(profileDashboardProvider);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    await ref.read(resourcesRepositoryProvider).delete(id);
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
