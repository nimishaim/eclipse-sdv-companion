import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String time(DateTime dateTime) =>
      _timeFormat.format(dateTime.toLocal());

  static String dateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 5) {
      return 'just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  static String speed(double kmh) => kmh.toStringAsFixed(1);

  static String batterySoc(double soc) => '${soc.toStringAsFixed(0)}%';

  static String steeringAngle(double deg) => '${deg.toStringAsFixed(1)}°';

  static String temperature(double celsius) =>
      '${celsius.toStringAsFixed(1)}°C';
}
