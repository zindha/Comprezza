import 'package:comprezza/features/compressor/presentation/batch_compression_controller.dart';
import 'package:flutter_test/flutter_test.dart';

BatchImageItem image(String id) => BatchImageItem(
  id: id,
  path: '/missing/$id.jpg',
  name: '$id.jpg',
  bytes: 2 * 1024 * 1024,
  width: 2400,
  height: 1600,
  format: 'JPEG',
);

void main() {
  // Regression guard for the original suite freeze: awaiting the controller's
  // workflow from a testWidgets fake-async zone deadlocked forever because the
  // analysis loop yields on a zero-duration timer that only fires when the
  // test clock advances. This stays a plain test() so real timers fire; the
  // real-time bound turns any future never-completing controller change into
  // a fast failure instead of a 30-minute hang.
  test(
    'regression: original hang scenario completes within a real-time bound',
    () async {
      var shouldFail = true;
      final BatchCompressionController featureController =
          BatchCompressionController(
            picker: () async => <BatchImageItem>[],
            processor:
                (BatchImageItem item, BatchCompressionSettings settings) async {
                  if (shouldFail) {
                    shouldFail = false;
                    throw StateError('temporary failure');
                  }
                  return const BatchImageResult(
                    outputPath: '/missing/output.jpg',
                    outputBytes: 500,
                  );
                },
          );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('retry')]);
      await featureController.startProcessing().timeout(
        const Duration(seconds: 5),
      );
      expect(featureController.phase, BatchWorkflowPhase.completed);
      expect(featureController.failedCount, 1);
    },
  );
}
