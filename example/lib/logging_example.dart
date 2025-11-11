import 'package:flutter/material.dart';
import 'package:guideline_cam/guideline_cam.dart';

/// Example demonstrating debug logging optimization
void configureLoggingExample() {
  // Example 1: Production configuration (recommended for release builds)
  GuidelineCam.configureLogging(LoggerConfig.production);

  // Example 2: Development configuration (recommended for debug builds)
  GuidelineCam.configureLogging(LoggerConfig.development);

  // Example 3: Verbose configuration (for debugging complex issues)
  GuidelineCam.configureLogging(LoggerConfig.verbose);

  // Example 4: Custom configuration
  GuidelineCam.configureLogging(LoggerConfig(
    enabled: true,
    level: LogLevel.info,
    useConsole: true,
    includeStackTrace: false,
    logInRelease: false,
    customLogger: (message) {
      // Integrate with your logging framework
      // e.g., Firebase Crashlytics, Sentry, or custom analytics
      print('[CUSTOM] $message');
    },
  ));

  // Example 5: Performance monitoring
  GuidelineCam.enablePerformanceTiming = true;
}

/// Example of logging integration in production
class ProductionLoggingSetup {
  static void initialize() {
    // Configure logging for production
    GuidelineCam.configureLogging(LoggerConfig(
      enabled: true,
      level: LogLevel.warn, // Only warnings and errors in production
      useConsole: false, // Don't use console in production
      includeStackTrace: true, // Include stack traces for error reporting
      logInRelease: true,
      customLogger: (message) {
        // Send to your logging service
        _sendToAnalytics(message);
      },
    ));
  }

  static void _sendToAnalytics(String message) {
    // Integrate with your preferred logging service
    // Firebase Crashlytics, Sentry, LogRocket, etc.
  }
}

/// Example of development setup with detailed logging
class DevelopmentLoggingSetup {
  static void initialize() {
    // Configure logging for development
    GuidelineCam.configureLogging(LoggerConfig.development);

    // Enable performance timing for optimization
    GuidelineCam.enablePerformanceTiming = true;
  }
}

/// Widget demonstrating logging integration
class LoggingExampleWidget extends StatelessWidget {
  const LoggingExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logging Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Logging Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Configuration buttons
            ElevatedButton(
              onPressed: () {
                GuidelineCam.configureLogging(LoggerConfig.production);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Production logging configured')),
                );
              },
              child: const Text('Configure Production Logging'),
            ),

            ElevatedButton(
              onPressed: () {
                GuidelineCam.configureLogging(LoggerConfig.development);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Development logging configured')),
                );
              },
              child: const Text('Configure Development Logging'),
            ),

            ElevatedButton(
              onPressed: () {
                GuidelineCam.configureLogging(LoggerConfig.verbose);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verbose logging configured')),
                );
              },
              child: const Text('Configure Verbose Logging'),
            ),

            const SizedBox(height: 24),

            // Current configuration display
            const Text(
              'Current Configuration:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Enabled: ${GuidelineCam.loggingConfig.enabled}'),
            Text('Level: ${GuidelineCam.loggingConfig.level.name}'),
            Text('Performance Timing: ${GuidelineCam.enablePerformanceTiming}'),
            Text('Log in Release: ${GuidelineCam.loggingConfig.logInRelease}'),
          ],
        ),
      ),
    );
  }
}