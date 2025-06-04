import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

typedef ResultVoid = Future<Either<Failure, void>>;
typedef ResultFuture<T> = Future<Either<Failure, T>>;

abstract class UseCase<Type, Params> {
  const UseCase();
  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  const UseCaseWithoutParams();
  ResultFuture<Type> call();
}

abstract class UseCaseVoid<Params> {
  const UseCaseVoid();
  ResultVoid call(Params params);
}

abstract class UseCaseVoidWithoutParams {
  const UseCaseVoidWithoutParams();
  ResultVoid call();
}
