import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:claim_investigation/widgets/app_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends BasePage {
  static const routeName = '/forgotPasswordScreen';

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends BaseState<BasePage> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailTextController = TextEditingController();

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

  Future<void> _handleForgotPassword() async {
    if (_validateInputs()) {
      try {
        final success = await Provider.of<AuthProvider>(context, listen: false)
            .forgotPassword(_emailTextController.text.trim());
        if (success) {
          showAdaptiveAlertDialog(context: context, title: "Success", content: 'Temporary Password has been sent to your registered Email ID', defaultActionText: 'Ok', defaultAction: () {
            Navigator.pop(context);
          });
        } else {}
      } catch (error) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _passwordFormKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: appHelper.isTablet(context)
                            ? SizeConfig.screenHeight * 0.2
                            : SizeConfig.screenHeight * 0.1),
                    AppFormTextField(
                      hintText: 'Enter your username',
                      hintLabel: 'Username',
                      controller: _emailTextController,
                      ctx: context,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      onSubmit: (_) {
                        FocusScope.of(context).requestFocus(new FocusNode());
                      },
                      validator: (email) {
                        if (email.toString().trim() == "") {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: double.maxFinite,
                      height: 50,
                      child: CupertinoButton(
                        color: Theme.of(context).primaryColor,
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _handleForgotPassword();
                        },
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
