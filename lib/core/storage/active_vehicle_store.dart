import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActiveVehicleStore {
  Future<String?> read(String uid);

  Future<void> write(String uid, String vehicleId);

  Future<void> clear(String uid);
}

class SharedPreferencesActiveVehicleStore implements ActiveVehicleStore {
  SharedPreferencesActiveVehicleStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  String _key(String uid) => 'active_vehicle_id_$uid';

  @override
  Future<String?> read(String uid) => _preferences.getString(_key(uid));

  @override
  Future<void> write(String uid, String vehicleId) {
    return _preferences.setString(_key(uid), vehicleId);
  }

  @override
  Future<void> clear(String uid) => _preferences.remove(_key(uid));
}

final activeVehicleStoreProvider = Provider<ActiveVehicleStore>((ref) {
  return SharedPreferencesActiveVehicleStore(
    ref.watch(sharedPreferencesProvider),
  );
});
