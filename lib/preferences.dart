import 'package:hive_flutter/hive_flutter.dart';

class Preferences {
  static const boxName = 'akiba-box';
  static late Box omeifeBox;

  static Future<void> initialize() async {
    omeifeBox = await Hive.openBox(boxName);
  }

  static Future<void> closeBox() async {
    await omeifeBox.close();
  }

  static Future<int> clearBox() async {
    return await omeifeBox.clear();
  }

  static Future<void> deleteData(String key) async {
    await omeifeBox.delete(key);
  }

  static Future<void> deleteMultiple(List<String> keys) async {
    await omeifeBox.deleteAll(keys);
  }

  static bool containsKey(String key) {
    return omeifeBox.containsKey(key);
  }

  static bool isBoxOpen() {
    return omeifeBox.isOpen;
  }

  static Future<dynamic> getData(String key) async {
    return await omeifeBox.get(key);
  }

  static Future<void> saveData(String key, dynamic value) async {
    await omeifeBox.put(key, value);
  }

  static Future<void> saveMultipleData(Map<String, dynamic> entries) async {
    await omeifeBox.putAll(entries);
  }
}
