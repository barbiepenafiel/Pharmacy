import 'package:logger/logger.dart';

/// Centralized logging service for the pharmacy app
/// Replaces raw print() statements with structured logging
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  late final Logger _logger;

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: Level.debug, // Set to Level.info for production
    );
  }

  /// Log debug messages (lowest priority)
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages (general information)
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages (potential issues)
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages (runtime errors)
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors (crashes)
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Set log level (debug, info, warning, error, fatal)
  void setLevel(Level level) {
    Logger.level = level;
  }
}

/// Global logger instance for convenience
final logger = LoggerService();
