abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const history = '/history';
  static const schedules = '/schedules';
  static const profile = '/profile';
  static const vehicles = '/vehicles';
  static const vehicleNew = '/vehicles/new';
  static const serviceRecordNew = '/history/new';
  static const serviceScheduleNew = '/schedules/new';

  static String vehicleDetail(String vehicleId) => '/vehicles/$vehicleId';

  static String vehicleEdit(String vehicleId) => '/vehicles/$vehicleId/edit';

  static String serviceRecordDetail(String recordId) => '/history/$recordId';

  static String serviceRecordEdit(String recordId) {
    return '/history/$recordId/edit';
  }

  static String serviceScheduleDetail(String scheduleId) {
    return '/schedules/$scheduleId';
  }

  static String serviceScheduleEdit(String scheduleId) {
    return '/schedules/$scheduleId/edit';
  }
}
