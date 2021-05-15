import 'package:claim_investigation/models/user_model.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSharedPref {
  final String PREF_USER_DATA = "USER_DATA";
  final String PREF_TOKEN_DATA = "TOKEN_DATA";
  final String PREF_LAST_SYNC_DATE = 'PREF_LAST_SYNC_DATE';
  final String PREF_SEL_CASE_TYPE = 'PREF_SEL_CASE_TYPE';

  static AppSharedPref _instance;
  static SharedPreferences _preferences;
  final key = Key.fromUtf8('akjnoivak101935naoigadjaafafd2f3');
  final iv = IV.fromLength(16);
  Encrypter encrypter;

  AppSharedPref() {
    encrypter = Encrypter(AES(key));
  }

  static Future<AppSharedPref> getInstance() async {
    if (_instance == null) {
      _instance = AppSharedPref();
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    return _instance;
  }

  void _saveToDisk<T>(String key, T content) {
    if (content is String) {
      _preferences.setString(key, content);
    }
    if (content is bool) {
      _preferences.setBool(key, content);
    }
    if (content is int) {
      _preferences.setInt(key, content);
    }
    if (content is double) {
      _preferences.setDouble(key, content);
    }
    if (content is List<String>) {
      _preferences.setStringList(key, content);
    }
  }

  dynamic _getFromDisk(String key) {
    var value = _preferences.get(key);
    // appPrint('(TRACE) AppSharedPref:_getFromDisk. key: $key value: $value');
    return value;
  }

  /// User Data
  set user(UserModel userModel) {
    final encrypted =
        encrypter.encrypt(json.encode(userModel.toJson()), iv: iv);
    _saveToDisk(PREF_USER_DATA, encrypted.base64);
  }

  UserModel get user {
    var userJson = _getFromDisk(PREF_USER_DATA);
    if (userJson == null) {
      return null;
    }
    userJson = encrypter.decrypt(Encrypted.from64(userJson), iv: iv);
    return UserModel.fromJson(json.decode(userJson));
  }

  removeUserModel() {
    _preferences.remove(PREF_USER_DATA);
  }

  /// Sync date
  set syncedDate(DateTime dateTime) {
    _saveToDisk(PREF_LAST_SYNC_DATE, dateTime.millisecondsSinceEpoch);
  }

  DateTime get syncedDate {
    int timestamp = _getFromDisk(PREF_LAST_SYNC_DATE);
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Type
  set caseTypeSelected(String type) {
    _saveToDisk(PREF_SEL_CASE_TYPE, type);
  }

  String get caseTypeSelected {
    return _getFromDisk(PREF_SEL_CASE_TYPE);
  }

  void clearUserData() {
    removeUserModel();
  }

  void clearAllData() {
    _preferences.clear();
  }
}
