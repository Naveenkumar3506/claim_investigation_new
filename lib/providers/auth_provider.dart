import 'dart:convert';
import 'package:claim_investigation/base/base_provider.dart';
import 'package:claim_investigation/service/api_client.dart';
import 'package:claim_investigation/service/api_constants.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/app_log.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends BaseProvider {
  UserModel currentUser;
  bool _isProfileUpdated = false;

  bool get isProfileUpdated => _isProfileUpdated;

  set isProfileUpdated(bool value) {
    _isProfileUpdated = value;
    notifyListeners();
  }

  bool get isAuth {
    currentUser = pref.user;
    return currentUser != null;
  }

  Future<UserModel> authenticate(String email, String password) async {
    showLoadingIndicator(hint: "Signing In...");
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_USER_LOGIN,
        method: ApiMethod.POST,
        body: {
          'username': email,
          'password': password,
          'version': ApiConstant.API_VERSION_NUM
        },
        withAuth: false);
    hideLoadingIndicator();
    response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      currentUser = null;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      currentUser = UserModel.fromJson(r);
      // // Save to preference
      // super.pref.user = currentUser;
      // notifyListeners();
    });
    return currentUser;
  }

  Future<bool> forgotPassword(String username) async {
    showLoadingIndicator();
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_FORGOT_PASSWORD,
        method: ApiMethod.POST,
        body: {'username': username, 'version': ApiConstant.API_VERSION_NUM},
        withAuth: false);
    hideLoadingIndicator();
    return response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      return false;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      return true;
    });
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    showLoadingIndicator(hint: 'Updating Password');
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_CHANGE_PASSWORD,
        method: ApiMethod.POST,
        body: {
          'oldpassword': oldPassword,
          'newpassword': newPassword,
          'username': pref.user.username,
          'version': ApiConstant.API_VERSION_NUM
        });
    hideLoadingIndicator();
    return response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      return false;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      return true;
    });
  }

  Future generateOtp(UserModel userModel, int otp) async {
    showLoadingIndicator(hint: "Requesting OTP...");
    Map<String, dynamic> body = {
      "REQ": {
        "MOB": userModel.mobileNumber,
        "AC": "SOGSCD",
        "APPID": "website",
        "LID": "2623511857455",
        "BTI": "website",
        "OTP": otp.toString(),
        "CAT": "PAOTP",
        "TYPE": "B",
        "EMLID": userModel.userEmail
      }
    };

    print(body);

    final response = await http.post(ApiConstant.API_OTP,
        body: json.encode(body));
    print(response.body);
    hideLoadingIndicator();
  }

  void saveUser() {
    // Save to preference
    super.pref.user = currentUser;
    notifyListeners();
  }

  void clearUserData() {
    pref.removeUserModel();
    currentUser = null;
    //
    notifyListeners();
  }
}
