import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OTP"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
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
                // maskCharacter: "😎",
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
              height: 40,
            ),
            Container(
              padding: EdgeInsets.all(20.0),
              width: double.maxFinite,
              child: CupertinoButton(
                color: Theme.of(context).primaryColor,
                child: Text(
                  'Verify',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: (){
                  validateOTP(controller.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  validateOTP(String otp) {
    if (otp == "1234") {
    } else {
      setState(() {
        hasError = true;
      });
    }
  }
}
