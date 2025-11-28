abstract class Failure {
  final String? message;
  Failure({this.message});
}

class ServerFailure extends Failure {
  ServerFailure({String? message}) : super(message: message);
}

class CacheFailure extends Failure {
  CacheFailure({String? message}) : super(message: message);
}

class NetworkFailure extends Failure {
  NetworkFailure({String? message}) : super(message: message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message: message);
}
