import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info/package_info.dart';

class AppHelper {
  static AppHelper _instance;
  static AndroidDeviceInfo _androidInfo;
  static IosDeviceInfo _iosInfo;
  static PackageInfo packageInfo;

  static Future<AppHelper> getInstance() async {
    if (_instance == null) {
      _instance = AppHelper();
    }
    if (Platform.isAndroid) {
      _androidInfo = await DeviceInfoPlugin().androidInfo;
    } else if (Platform.isIOS) {
      _iosInfo = await DeviceInfoPlugin().iosInfo;
    }
    packageInfo = await PackageInfo.fromPlatform();
    return _instance;
  }

  String getDevicePlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    }
    return '';
  }

  String getDeviceModel() {
    if (Platform.isAndroid && _androidInfo != null) {
      final String manufacturer = _androidInfo.manufacturer;
      final String model = _androidInfo.model;
      return '$manufacturer $model';
    } else if (Platform.isIOS && _iosInfo != null) {
      final String name = _iosInfo.utsname.machine;
      return '$name';
    }
    return '';
  }

  String getVersionNumber() {
    if (packageInfo != null) {
      return packageInfo.version;
    }
    return '';
  }

  String getBuildNumber() {
    if (packageInfo != null) {
      return packageInfo.buildNumber;
    }
    return '';
  }

  bool isTablet(BuildContext context) {
    if (Platform.isIOS) {
      return _iosInfo.model.toLowerCase() == "ipad";
    } else {
      // The equivalent of the "smallestWidth" qualifier on Android.
      var shortestSide = MediaQuery.of(context).size.shortestSide;
      // Determine if we should use mobile layout or not, 600 here is
      // a common breakpoint for a typical 7-inch tablet.
      return shortestSide > 600;
    }
  }
}

void showSuccessToast(String message) {
  Get.snackbar('Success', message,
      icon: Icon(Icons.done, color: Colors.white),
      backgroundColor: Colors.green,
      colorText: Colors.white);
}

void showErrorToast(String message) {
  Get.snackbar('Alert', message,
      icon: Icon(Icons.warning, color: Colors.white),
      backgroundColor: Colors.red,
      colorText: Colors.white);
}

void showInfoToast(String message) {
  Get.snackbar('Info', message,
      icon: Icon(Icons.info, color: Colors.white),
      backgroundColor: Colors.orange,
      colorText: Colors.white);
}
