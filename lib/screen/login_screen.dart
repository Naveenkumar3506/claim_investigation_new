import 'dart:math';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/screen/otp_screen.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:claim_investigation/widgets/app_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

import 'forgotpassword_screen.dart';

class LoginScreen extends BasePage {
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseState<BasePage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _userNameTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();
  final _newUser = UserModel();

  // Initially password is obscure
  bool _passwordObscureText = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      // _userNameTextController.text = '6363';
      // _passwordTextController.text = 'password';
    });
  }

  @override
  void dispose() {
    _userNameTextController.dispose();
    _passwordTextController.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (_loginFormKey.currentState.validate()) {
      print('Form is valid');
      _loginFormKey.currentState.save();
      return true;
    } else {
      print('Form is invalid');
      return false;
    }
  }

  Future login() async {
    if (_validateInputs()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        final user = await authProvider.authenticate(
            _userNameTextController.text.trim(),
            _passwordTextController.text.trim());
        if (user != null) {
          var random = new Random();
          int min = 1000,
              max = 9999;
          int num = min + random.nextInt(max - min);
          authProvider.generateOtp(user, num).then((value) {
            Get.toNamed(OtpScreen.routeName, arguments: {
              "user": user,
              "otp": num
            });
          });
        }
      } catch (error) {
        Navigator.pop(context);
        print("mmm ${error.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //       image: AssetImage('assets/images/ic_bg.png'), fit: BoxFit.cover),
        // ),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Sign In'),
            actions: [
              Container(padding: EdgeInsets.only(right: 10),
                child: Image.asset('assets/images/ic_logo.jpeg'),
                height: 40,
                width: 40,)
            ],
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Form(
                key: _loginFormKey,
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
                        controller: _userNameTextController,
                        ctx: context,
                        focusNode: _emailNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        onSubmit: (_) {
                          FocusScope.of(context).requestFocus(_passwordNode);
                        },
                        validator: (email) {
                          if (email == "") {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      // AppFormTextField(
                      //   hintText: 'Enter your password',
                      //   hintLabel: 'Password',
                      //   controller: _passwordTextController,
                      //   ctx: context,
                      //   focusNode: _passwordNode,
                      //   obscureText: _passwordObscureText,
                      //   suffix: IconButton(
                      //     icon: _passwordObscureText
                      //         ? Icon(Icons.visibility)
                      //         : Icon(Icons.visibility_off),
                      //     onPressed: () {
                      //       setState(() {
                      //         _passwordObscureText = !_passwordObscureText;
                      //       });
                      //     },
                      //   ),
                      //   validator: (value) {
                      //     if (value == "") {
                      //       return 'Please enter password';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(vertical: 10.0),
                      //     child: InkWell(
                      //       child: Text(
                      //         'Forgot Password?',
                      //         textAlign: TextAlign.end,
                      //         style: TextStyle(),
                      //       ),
                      //       onTap: () {
                      //         Navigator.of(context)
                      //             .pushNamed(ForgotPasswordScreen.routeName);
                      //       },
                      //     ),
                      //   )
                      // ]),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.maxFinite,
                        child: CupertinoButton(
                          color: Theme
                              .of(context)
                              .primaryColor,
                          child: Text(
                            'Sign In',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => login(),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
