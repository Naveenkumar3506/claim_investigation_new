import 'dart:math';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:provider/provider.dart';

class OtpScreen extends BasePage {
  static const routeName = '/otpScreen';

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends BaseState<OtpScreen> {
  TextEditingController controller = TextEditingController(text: "");
  String thisText = "";
  int pinLength = 4;
  bool hasError = false;
  String errorMessage;
  int otp;
  UserModel userModel;

  @override
  void initState() {
    if (Get.arguments != null) {
      final arguments = Get.arguments;
      otp = arguments["otp"];
      userModel = arguments["user"];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OTP"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                    "Please enter the OTP received at registered mobile number."),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: PinCodeTextField(
                  autofocus: true,
                  controller: controller,
                  highlight: true,
                  highlightColor: Colors.black,
                  defaultBorderColor: Colors.grey,
                  hasTextBorderColor: Colors.green,
                  maxLength: pinLength,
                  hasError: hasError,
                  // highlightPinBoxColor: Colors.orange,
                  // hideCharacter: true,
                  // maskCharacter: "😎",s
                  onTextChanged: (text) {
                    setState(() {
                      hasError = false;
                    });
                  },
                  onDone: (text) {
                    print("DONE CONTROLLER ${controller.text}");
                  },
                  pinBoxWidth: 50,
                  pinBoxHeight: 60,
                  hasUnderline: true,
                  wrapAlignment: WrapAlignment.spaceAround,
                  pinBoxDecoration:
                      ProvidedPinBoxDecoration.defaultPinBoxDecoration,
                  pinTextStyle: TextStyle(fontSize: 22.0),
                  pinTextAnimatedSwitcherTransition:
                      ProvidedPinBoxTextAnimation.scalingTransition,
//                    pinBoxColor: Colors.green[100],
                  pinTextAnimatedSwitcherDuration: Duration(milliseconds: 300),
//                    highlightAnimation: true,
                  highlightAnimationBeginColor: Colors.black,
                  highlightAnimationEndColor: Colors.white12,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: InkWell(
                    child: Text(
                      'Resend OTP',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: primaryColor),
                    ),
                    onTap: () {
                      var random = new Random();
                      int min = 1000, max = 9999;
                      int num = min + random.nextInt(max - min);
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      authProvider.generateOtp(userModel, num).then((value) {
                        otp = num;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 30,
                )
              ]),
              SizedBox(
                height: 10,
              ),
              Container(
                padding: EdgeInsets.all(20.0),
                width: double.maxFinite,
                child: CupertinoButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(
                    'Verify OTP',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    validateOTP(controller.text);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  validateOTP(String otpText) {
    if (int.parse(otpText) == otp) {
      Provider.of<AuthProvider>(context, listen: false).saveUser();
      Get.back();
    } else {
      setState(() {
        hasError = true;
      });
      showErrorToast("Invalid OTP.");
    }
  }
}
