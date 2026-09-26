String? publicProfilePath(String? userId) {
  final normalized = userId?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (const {'settings', 'edit', 'setup'}.contains(normalized.toLowerCase())) {
    return null;
  }
  return '/profile/${Uri.encodeComponent(normalized)}';
}
