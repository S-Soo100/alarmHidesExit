import 'package:logger/web.dart';

mixin LoggerMixin {
  var logger = Logger(printer: PrettyPrinter());
  void log(String message) {
    logger.w(message);
  }
}
