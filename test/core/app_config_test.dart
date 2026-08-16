import 'package:comprezza/app/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release configuration disables diagnostics and performance hooks', () {
    const AppConfig config = AppConfig(
      environment: AppEnvironment.release,
      buildType: BuildType.release,
      runtimeEnvironment: Environment.production,
      enableDiagnostics: false,
      enablePerformanceMonitoring: false,
    );

    expect(config.isRelease, isTrue);
    expect(config.enableDiagnostics, isFalse);
    expect(config.enablePerformanceMonitoring, isFalse);
  });

  test('feature flags default to disabled', () {
    const FeatureFlags flags = FeatureFlags();
    expect(flags.enableHistory, isFalse);
    expect(flags.enableBatchCompression, isFalse);
    expect(flags.enableFolderCompression, isFalse);
    expect(flags.enableBenchmarkMode, isFalse);
  });
}
