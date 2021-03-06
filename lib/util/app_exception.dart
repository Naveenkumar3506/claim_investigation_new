
class AppException implements Exception {
  final String msg;
  const AppException(this.msg);
  String toString() => '$msg';
}