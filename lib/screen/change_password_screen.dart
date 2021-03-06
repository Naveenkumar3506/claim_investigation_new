import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:claim_investigation/widgets/app_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends BasePage {
  static const routeName = '/changePasswordScreen';

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends BaseState<ChangePasswordScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordTextController = TextEditingController();
  final _newPasswordTextController = TextEditingController();

  // Initially password is obscure
  bool _oldPasswordObscureText = true;
  bool _newPasswordObscureText = true;

  @override
  void initState() {
    super.initState();
  }

  bool _validateInputs() {
    if (_passwordFormKey.currentState.validate()) {
      print('Form is valid');
      _passwordFormKey.currentState.save();
      return true;
    } else {
      print('Form is invalid');
      return false;
    }
  }

  changePassword() async {
    if (_validateInputs()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        final success = await authProvider.changePassword(
            _oldPasswordTextController.text.trim(),
            _newPasswordTextController.text.trim());
        if (success) {
          Get.back();
          showSuccessToast('Password changed successfully');
        }
      } catch (error) {
        print("mmm ${error.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text('Change Password'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: SafeArea(
            child: Form(
              key: _passwordFormKey,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                        height: appHelper.isTablet(context)
                            ? SizeConfig.screenHeight * 0.2
                            : SizeConfig.screenHeight * 0.1),
                    AppFormTextField(
                      autofocus: true,
                      hintText: 'Enter your password',
                      hintLabel: 'Current Password',
                      controller: _oldPasswordTextController,
                      ctx: context,
                      obscureText: _oldPasswordObscureText,
                      suffix: IconButton(
                        icon: _oldPasswordObscureText
                            ? Icon(Icons.visibility)
                            : Icon(Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _oldPasswordObscureText = !_oldPasswordObscureText;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == "") {
                          return 'Please enter current password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    AppFormTextField(
                      hintText: 'Enter your password',
                      hintLabel: 'New Password',
                      controller: _newPasswordTextController,
                      ctx: context,
                      obscureText: _newPasswordObscureText,
                      suffix: IconButton(
                        icon: _newPasswordObscureText
                            ? Icon(Icons.visibility)
                            : Icon(Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _newPasswordObscureText = !_newPasswordObscureText;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == "") {
                          return 'Please enter new password';
                        } else if (value.toString().trim() ==
                            _oldPasswordTextController.text.trim()) {
                          return "New password is same as old password";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.maxFinite,
                      child: CupertinoButton(
                        color: Theme.of(context).primaryColor,
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => changePassword(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
