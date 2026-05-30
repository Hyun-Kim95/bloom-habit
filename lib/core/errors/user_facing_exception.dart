/// Exception carrying a message safe to show in UI (e.g. localized business rule).
class UserFacingException implements Exception {
  const UserFacingException(this.message);

  final String message;

  @override
  String toString() => message;
}
