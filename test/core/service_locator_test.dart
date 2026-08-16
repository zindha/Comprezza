import 'package:comprezza/app/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates lazy singletons once and factories per resolution', () {
    final ServiceLocator locator = ServiceLocator();
    int singletonCount = 0;
    int factoryCount = 0;
    locator.registerLazySingleton<_Value>((_) {
      singletonCount++;
      return _Value();
    });
    locator.registerFactory<_FactoryValue>((_) {
      factoryCount++;
      return _FactoryValue();
    });

    expect(singletonCount, 0);
    final _Value first = locator.get<_Value>();
    final _Value second = locator.get<_Value>();
    expect(first, same(second));
    expect(singletonCount, 1);
    final _FactoryValue firstFactory = locator.get<_FactoryValue>();
    final _FactoryValue secondFactory = locator.get<_FactoryValue>();
    expect(firstFactory, isNot(same(secondFactory)));
    expect(factoryCount, 2);
    locator.dispose();
  });

  test('disposes created disposable singletons exactly once', () {
    final ServiceLocator locator = ServiceLocator();
    final _DisposableValue value = _DisposableValue();
    locator.registerLazySingleton<_DisposableValue>((_) => value);

    final _DisposableValue resolved = locator.get<_DisposableValue>();
    expect(resolved, same(value));
    locator.dispose();
    locator.dispose();

    expect(value.disposeCount, 1);
  });

  test('resolves async lazy singleton once', () async {
    final ServiceLocator locator = ServiceLocator();
    int count = 0;
    locator.registerLazyAsyncSingleton<_Value>((_) async {
      count++;
      return _Value();
    });

    final _Value first = await locator.getAsync<_Value>();
    final _Value second = await locator.getAsync<_Value>();

    expect(first, same(second));
    expect(count, 1);
    locator.dispose();
  });
}

class _Value {}

class _FactoryValue {}

final class _DisposableValue implements Disposable {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
  }
}
