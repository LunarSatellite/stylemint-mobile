import 'package:fpdart/fpdart.dart';
import '../error/failure.dart';

/// Base interface for every UseCase.
/// [Type] — the success return type.
/// [Params] — the input; use [NoParams] when there are none.
abstract interface class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Pass when the use case requires no parameters.
class NoParams {
  const NoParams();
}
