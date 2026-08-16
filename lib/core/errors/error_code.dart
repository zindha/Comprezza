/// Stable machine-readable application error codes.
enum ErrorCode {
  /// An unexpected failure.
  unknown,

  /// A caller supplied an invalid value or attempted an invalid operation.
  invalidArgument,

  /// An operation was cancelled.
  cancelled,

  /// A required capability or service is unavailable.
  unavailable,

  /// The platform denied an operation.
  permissionDenied,

  /// A requested resource was not found.
  notFound,

  /// A local file operation failed.
  ioFailure,

  /// Cache cleanup failed.
  cacheCleanupFailed,

  /// A startup task failed.
  startupTaskFailed,

  /// Startup failed before the app became usable.
  startupFailed,

  /// The requested platform operation is unsupported.
  unsupportedPlatform,

  /// No image engine is configured.
  imageEngineUnconfigured,

  /// A generated path is outside the allowed storage boundary.
  unsafePath,

  /// A selected file cannot be decoded as a supported image.
  corruptedFile,

  /// A generated destination already exists.
  conflict,

  /// An operation exceeded its deadline.
  timeout,
}
