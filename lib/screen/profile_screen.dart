import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/screen/edit_profile_screen.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'change_password_screen.dart';

class ProfileScreen extends BasePage {
  static const routeName = '/profileScreen';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends BaseState<ProfileScreen> {
  File _imageFile;
  UserModel _userModel;
  String path = '';

  @override
  void initState() {
    if (pref.user != null) {
      _userModel = pref.user;
    }
    super.initState();
  }

  void _showLogoutAlert() {
    showAdaptiveAlertDialog(
        context: context,
        title: 'Log out?',
        content: 'Do you want to Log out?',
        cancelActionText: 'Cancel',
        defaultActionText: 'Log out',
        defaultActionColor: Colors.red,
        defaultAction: _logOut);
  }

  _logOut() {
    pref.clearUserData();
    Provider.of<AuthProvider>(context, listen: false).clearUserData();
    Provider.of<ClaimProvider>(context, listen: false).clearData();
  }

  File _getImage() {
    if (pref.user != null) {
      setState(() {
        _userModel = pref.user;
      });
    }
    bool _validImageURL = Uri.parse(_userModel.userImage).isAbsolute;
    if (!_validImageURL) {
      _imageFile = File("${pref.appDocPath}/${_userModel.userImage}");
      return _imageFile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusGained: () {
        setState(() {
          _imageFile = _getImage();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () {
                _showLogoutAlert();
              },
            ),
          ],
        ),
        body: Consumer<AuthProvider>(builder: (ctx, auth, _) {
          return Column(
            children: [
              Container(
                padding: EdgeInsetsDirectional.only(top: 15.0),
                width: double.maxFinite,
                height: appHelper.isTablet(context)
                    ? SizeConfig.screenWidth * 0.5
                    : SizeConfig.screenHeight * 0.32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 45,
                      child: _imageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _imageFile,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                      backgroundImage: (_userModel.userImage != null &&
                              _userModel.userImage != "" &&
                              Uri.parse(_userModel.userImage).isAbsolute)
                          ? CachedNetworkImageProvider(_userModel.userImage)
                          : AssetImage(
                              'assets/images/ic_profile_placeholder.jpg'),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      pref.user.username,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Text(
                      pref.user.userEmail != null ? pref.user.userEmail : '',
                      style: TextStyle(color: Colors.grey, fontSize: 13.0),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    TextButton(
                      onPressed: () {
                        Get.toNamed(EditProfileScreen.routeName);
                      },
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(color: primaryColor, fontSize: 13.0),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
                child: Container(
                  color: veryLightGrey,
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.lock,
                  color: primaryColor,
                ),
                title: Text(
                  'Change password',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Get.toNamed(ChangePasswordScreen.routeName);
                },
              ),
              Expanded(child: Container()),
              Center(
                child: Text(
                  'v' + appHelper.getVersionNumber(),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(
                height: 15,
              ),
            ],
          );
        }),
      ),
    );
  }
}
