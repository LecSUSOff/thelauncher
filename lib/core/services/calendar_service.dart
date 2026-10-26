import 'package:device_calendar/device_calendar.dart';

class CalendarService {
  static final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  static Future<List<Event>> fetchUpcomingEvents({
    int daysAhead = 2,
    int limit = 3,
  }) async {
    List<Event> upcomingEvents = [];
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !(permissionsGranted.data ?? false)) {
          return [];
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.data != null) {
        for (var calendar in calendarsResult.data!) {
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id,
            RetrieveEventsParams(
              startDate: DateTime.now(),
              endDate: DateTime.now().add(Duration(days: daysAhead)),
            ),
          );

          if (eventsResult.data != null) {
            upcomingEvents.addAll(eventsResult.data!);
          }
        }
      }
      upcomingEvents.sort((a, b) => (a.start as DateTime).compareTo(b.start as DateTime));
      return upcomingEvents.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
