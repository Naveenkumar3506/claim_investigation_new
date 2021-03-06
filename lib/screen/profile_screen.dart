import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'change_password_screen.dart';

class ProfileScreen extends BasePage {
  static const routeName = '/profileScreen';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends BaseState<ProfileScreen> {

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: ListView(
        children: [
          Container(
            padding: EdgeInsetsDirectional.only(top: 15.0),
            width: double.maxFinite,
            height: appHelper.isTablet(context)
                ? SizeConfig.screenWidth * 0.4
                : SizeConfig.screenHeight * 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: SizeConfig.screenHeight * 0.07,
                  // backgroundImage: _userModel.profileImage == null ||
                  //     _userModel.profileImage.isEmpty
                  //     ? AssetImage('assets/images/ic_profile_placeholder.jpg')
                  //     : CachedNetworkImageProvider(_userModel.profileImage),
                  backgroundImage:
                      AssetImage('assets/images/ic_profile_placeholder.jpg'),
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
                  height: 20,
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
            title: Text('Change password', style: TextStyle(color: Colors.black),),
            onTap: () {
              Get.toNamed(ChangePasswordScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
