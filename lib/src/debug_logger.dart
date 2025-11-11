import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Professional logging system for guideline_cam package
///
/// Provides structured logging with different levels and performance
/// optimization for production builds.
///
/// ## Zero Configuration Required
///
/// The logging system works out-of-the-box with intelligent defaults:
///
/// **Debug Builds (kDebugMode = true):**
/// - Shows debug, info, warn, and error messages
/// - Includes stack traces for debugging
/// - Uses console output
///
/// **Release Builds (kDebugMode = false):**
/// - Shows ONLY error messages (critical failures)
/// - No console output pollution
/// - No stack traces
/// - Optimized for production
///
/// Use `GuidelineCam.configureLogging()` only if you want custom behavior.
class GuidelineCamLogger {
  /// Singleton instance for consistent logging
  static final GuidelineCamLogger _instance = GuidelineCamLogger._internal();
  factory GuidelineCamLogger() => _instance;
  GuidelineCamLogger._internal();

  /// Configuration for logging behavior
  static LoggerConfig _config = _createDefaultConfig();

  /// Create intelligent default configuration based on build mode
  static LoggerConfig _createDefaultConfig() {
    if (kDebugMode) {
      // Development mode: detailed logging for debugging
      return const LoggerConfig(
        enabled: true,
        level: LogLevel.debug, // Show debug and above in development
        useConsole: true,
        includeStackTrace: true,
        logInRelease: false,
      );
    } else {
      // Release mode: only critical errors
      return const LoggerConfig(
        enabled: true,
        level: LogLevel.error, // Only errors in release
        useConsole: false, // No console pollution in release
        includeStackTrace: false, // No stack traces in release
        logInRelease: true, // Log even in release (for errors only)
      );
    }
  }

  /// Configure logging behavior
  static void configure(LoggerConfig config) {
    _config = config;
  }

  /// Get current configuration
  static LoggerConfig get config => _config;

  /// Log error messages - always logged regardless of build mode
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    // Early return optimization - check enabled first
    if (!_config.enabled) return;
    if (!_config.level.includes(LogLevel.error)) return;
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warn(String message, {Object? error}) {
    if (!_config.enabled) return;
    if (!_config.level.includes(LogLevel.warn)) return;
    _log('WARN', message, error: error);
  }

  /// Log info messages
  static void info(String message) {
    if (!_config.enabled) return;
    if (!_config.level.includes(LogLevel.info)) return;
    _log('INFO', message);
  }

  /// Log debug messages - automatically filtered by build mode
  static void debug(String message) {
    // Early return for release mode - no kDebugMode check needed inside
    if (!kDebugMode) return;
    if (!_config.enabled) return;
    if (!_config.level.includes(LogLevel.debug)) return;
    _log('DEBUG', message);
  }

  /// Log verbose messages - only in debug mode
  static void verbose(String message) {
    if (!kDebugMode) return;
    if (!_config.enabled) return;
    if (!_config.level.includes(LogLevel.verbose)) return;
    _log('VERBOSE', message);
  }

  /// Performance logging with timing
  static T time<T>(String operation, T Function() func,
      {bool logInRelease = false}) {
    if (!_config.enabled || (!kDebugMode && !logInRelease)) {
      return func();
    }

    final stopwatch = Stopwatch()..start();
    try {
      return func();
    } finally {
      stopwatch.stop();
      if (_config.level.includes(LogLevel.debug)) {
        debug('$operation took ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }

  /// Internal logging method
  static void _log(String level, String message,
      {Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';

    if (error != null) {
      _print('$logMessage\nError: $error');
      if (stackTrace != null && _config.includeStackTrace) {
        _print('Stack trace: $stackTrace');
      }
    } else {
      _print(logMessage);
    }
  }

  /// Print method that respects configuration
  static void _print(String message) {
    if (_config.useConsole) {
      if (kDebugMode) {
        print(message);
      } else if (_config.logInRelease) {
        // In release, use more sophisticated logging if available
        log(message);
      }
    }

    // Call custom logger if provided
    _config.customLogger?.call(message);
  }
}

/// Configuration for logger behavior
class LoggerConfig {
  /// Enable/disable logging
  final bool enabled;

  /// Minimum log level to output
  final LogLevel level;

  /// Use console print statements
  final bool useConsole;

  /// Include stack traces for errors
  final bool includeStackTrace;

  /// Log even in release builds
  final bool logInRelease;

  /// Custom logging function for integration with logging frameworks
  final void Function(String message)? customLogger;

  const LoggerConfig({
    this.enabled = true,
    this.level = LogLevel.info,
    this.useConsole = true,
    this.includeStackTrace = true,
    this.logInRelease = false,
    this.customLogger,
  });

  /// Default configuration for production
  static const LoggerConfig production = LoggerConfig(
    enabled: true,
    level: LogLevel.warn, // Only warnings and errors in production
    useConsole: true,
    includeStackTrace: false,
    logInRelease: true,
  );

  /// Default configuration for development
  static const LoggerConfig development = LoggerConfig(
    enabled: true,
    level: LogLevel.debug,
    useConsole: true,
    includeStackTrace: true,
    logInRelease: false,
  );

  /// Verbose configuration for debugging complex issues
  static const LoggerConfig verbose = LoggerConfig(
    enabled: true,
    level: LogLevel.verbose,
    useConsole: true,
    includeStackTrace: true,
    logInRelease: false,
  );

  /// Create a copy with modified values
  LoggerConfig copyWith({
    bool? enabled,
    LogLevel? level,
    bool? useConsole,
    bool? includeStackTrace,
    bool? logInRelease,
    void Function(String message)? customLogger,
  }) {
    return LoggerConfig(
      enabled: enabled ?? this.enabled,
      level: level ?? this.level,
      useConsole: useConsole ?? this.useConsole,
      includeStackTrace: includeStackTrace ?? this.includeStackTrace,
      logInRelease: logInRelease ?? this.logInRelease,
      customLogger: customLogger ?? this.customLogger,
    );
  }
}

/// Log levels for filtering messages
enum LogLevel {
  /// No logging
  off(0),

  /// Only errors
  error(1),

  /// Errors and warnings
  warn(2),

  /// Errors, warnings, and info
  info(3),

  /// Most messages including debug
  debug(4),

  /// All messages including verbose
  verbose(5);

  const LogLevel(this.value);
  final int value;

  /// Check if this level includes another level
  bool includes(LogLevel other) => value >= other.value;
}
