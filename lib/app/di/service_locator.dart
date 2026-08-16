import '../../core/errors/app_exception.dart';
import '../../core/errors/error_code.dart';

/// A disposable resource owned by a [ServiceLocator].
abstract interface class Disposable {
  /// Releases resources owned by this object.
  void dispose();
}

/// Synchronous factory used to lazily construct a registered service.
typedef SyncFactory<T> = T Function(ServiceLocator locator);

/// Asynchronous factory used to lazily construct a registered service.
typedef AsyncFactory<T> = Future<T> Function(ServiceLocator locator);

abstract interface class _Registration {
  Object? resolve(ServiceLocator locator);
  Future<Object?> resolveAsync(ServiceLocator locator);
  void disposeIfOwned();
}

final class _LazySingleton<T> implements _Registration {
  _LazySingleton(this.factory);

  final SyncFactory<T> factory;
  T? _instance;
  bool _created = false;

  @override
  Object? resolve(ServiceLocator locator) {
    if (!_created) {
      _instance = factory(locator);
      _created = true;
    }
    return _instance as T;
  }

  @override
  Future<Object?> resolveAsync(ServiceLocator locator) async =>
      resolve(locator);

  @override
  void disposeIfOwned() {
    if (_instance case final Disposable disposable) disposable.dispose();
  }
}

final class _Factory<T> implements _Registration {
  _Factory(this.factory);

  final SyncFactory<T> factory;

  @override
  Object? resolve(ServiceLocator locator) => factory(locator);

  @override
  Future<Object?> resolveAsync(ServiceLocator locator) async =>
      resolve(locator);

  @override
  void disposeIfOwned() {}
}

final class _AsyncLazySingleton<T> implements _Registration {
  _AsyncLazySingleton(this.factory);

  final AsyncFactory<T> factory;
  Future<T>? _pending;
  T? _instance;
  bool _disposed = false;
  bool _valueDisposed = false;

  @override
  Object? resolve(ServiceLocator locator) {
    throw const AppException(
      code: ErrorCode.invalidArgument,
      message: 'An asynchronous service must be resolved with getAsync.',
      isRecoverable: false,
    );
  }

  @override
  Future<Object?> resolveAsync(ServiceLocator locator) async {
    if (_disposed) {
      throw const AppException(
        code: ErrorCode.invalidArgument,
        message: 'The asynchronous service has been disposed.',
        isRecoverable: false,
      );
    }
    try {
      final T value = await (_pending ??= factory(locator));
      if (_disposed) {
        _disposeValueOnce(value);
        throw const AppException(
          code: ErrorCode.invalidArgument,
          message:
              'The asynchronous service was disposed during initialization.',
          isRecoverable: false,
        );
      }
      _instance = value;
      return value;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  void _disposeValueOnce(T value) {
    if (_valueDisposed) return;
    _valueDisposed = true;
    if (value case final Disposable disposable) disposable.dispose();
  }

  @override
  void disposeIfOwned() {
    _disposed = true;
    if (_instance case final T value) _disposeValueOnce(value);
  }
}

/// Scoped, manually owned service locator with lazy construction semantics.
///
/// This class is deliberately not a singleton. The application composition
/// root owns one instance and may create isolated instances in tests.
final class ServiceLocator implements Disposable {
  final Map<Type, _Registration> _registrations = <Type, _Registration>{};
  bool _disposed = false;

  /// Registers a lazily created singleton.
  void registerLazySingleton<T>(SyncFactory<T> factory) {
    _ensureActive();
    _registerUnique<T>(_LazySingleton<T>(factory));
  }

  /// Registers a factory that creates a new instance for every resolution.
  void registerFactory<T>(SyncFactory<T> factory) {
    _ensureActive();
    _registerUnique<T>(_Factory<T>(factory));
  }

  /// Registers a lazily created asynchronous singleton.
  void registerLazyAsyncSingleton<T>(AsyncFactory<T> factory) {
    _ensureActive();
    _registerUnique<T>(_AsyncLazySingleton<T>(factory));
  }

  void _registerUnique<T>(_Registration registration) {
    if (_registrations.containsKey(T)) {
      throw AppException(
        code: ErrorCode.invalidArgument,
        message: 'Service already registered: $T',
        isRecoverable: false,
      );
    }
    _registrations[T] = registration;
  }

  /// Resolves a synchronously constructible service.
  T get<T>() {
    _ensureActive();
    final _Registration? registration = _registrations[T];
    if (registration == null) {
      throw AppException(
        code: ErrorCode.notFound,
        message: 'Service not registered: $T',
        isRecoverable: false,
      );
    }
    return registration.resolve(this) as T;
  }

  /// Resolves an asynchronous service.
  Future<T> getAsync<T>() async {
    _ensureActive();
    final _Registration? registration = _registrations[T];
    if (registration == null) {
      throw AppException(
        code: ErrorCode.notFound,
        message: 'Service not registered: $T',
        isRecoverable: false,
      );
    }
    return await registration.resolveAsync(this) as T;
  }

  /// Returns whether a type has been registered in this active scope.
  bool contains<T>() {
    _ensureActive();
    return _registrations.containsKey(T);
  }

  void _ensureActive() {
    if (_disposed) {
      throw const AppException(
        code: ErrorCode.invalidArgument,
        message: 'Service locator has been disposed.',
        isRecoverable: false,
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    for (final _Registration registration in _registrations.values) {
      registration.disposeIfOwned();
    }
    _registrations.clear();
    _disposed = true;
  }
}
