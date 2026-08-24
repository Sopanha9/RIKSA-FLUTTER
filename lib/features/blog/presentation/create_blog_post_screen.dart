import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_api.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';

class CreateBlogPostScreen extends ConsumerStatefulWidget {
  const CreateBlogPostScreen({super.key});

  @override
  ConsumerState<CreateBlogPostScreen> createState() =>
      _CreateBlogPostScreenState();
}

class _CreateBlogPostScreenState extends ConsumerState<CreateBlogPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  String? _categoryId;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final cover = _coverCtrl.text.trim();
      await ref.read(blogApiProvider).createPost(
            CreateBlogPostRequest(
              title: _titleCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              coverUrl: cover.isEmpty ? null : cover,
              categoryId: _categoryId!,
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on DioException catch (e) {
      _showError(dioErrorMessage(e));
    } catch (_) {
      _showError('Something went wrong');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: _submitted ? _buildPendingReview() : _buildForm(),
    );
  }

  Widget _buildPendingReview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Pending review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your post was submitted and will appear in the feed once a '
              'moderator approves it.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(true),
              child: const Text('Back to Feed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final categoriesAsync = ref.watch(blogCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your post a title',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length > 200) return 'Max 200 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, _) => Text(
                'Could not load categories',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              data: (categories) => DropdownButtonFormField<String>(
                key: ValueKey(_categoryId),
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Category is required' : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverCtrl,
              decoration: const InputDecoration(
                labelText: 'Cover image URL (optional)',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v != null && v.trim().length > 2000) {
                  return 'Max 2000 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              minLines: 8,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Write your article...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Content is required';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}
