class TaskException implements Exception {
  final String message;

  TaskException(this.message);

  @override
  String toString() => message;
}

class TaskNotFoundException extends TaskException {
  TaskNotFoundException(int id) : super('Task with ID $id is not found');
}

class InvalidTaskException extends TaskException {
  InvalidTaskException(super.message);
}
