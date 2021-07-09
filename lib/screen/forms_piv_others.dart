import 'dart:convert';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_toast.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PIVOthersForm extends BasePage {
  static const routeName = '/pivOthersForm';

  @override
  _PIVOthersFormState createState() => _PIVOthersFormState();
}

class _PIVOthersFormState extends BaseState<PIVOthersForm> {
  List selectedQuestions = [];

  @override
  void initState() {
    Future.delayed(Duration(milliseconds: 50)).then((value) => getQuestions());
    super.initState();
  }

  getQuestions() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString("assets/images/piv_questions.json");
    final aaa = Map<String, dynamic>.from(json.decode(data));
    selectedQuestions = aaa["Others"];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PIV Form Others"),
      ),
      body: SafeArea(
          child: ListView.builder(
        itemCount: selectedQuestions.length + 1,
        itemBuilder: (ctx, index) {
          if (index == selectedQuestions.length) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    // color: primaryColor,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
                    ),
                    onPressed: () async {
                      Get.back();
                    },
                    child: Text(
                      'Prev',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                   // color: primaryColor,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
                    ),
                    onPressed: () async {
                      if (checkFormFilled()) {
                      } else {
                        AppToast.toast(
                          'Please answer all the questions.',
                        );
                      }
                    },
                    child: Text(
                      'Submit Form',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final question = selectedQuestions[index];
            final type = question["type"];
            TextEditingController _controller = TextEditingController();
            _controller.text = selectedQuestions[index]["answer"] ?? "";
            TextEditingController _dateController = TextEditingController();
            _dateController.text = selectedQuestions[index]["answer"] ?? "";
            print(index.toString());
            EmployeeOptions _eOptions;
            Options _options;
            if (type == "option") {
              if (selectedQuestions[index]["answer"] == "Yes") {
                _options = Options.yes;
              } else if (selectedQuestions[index]["answer"] == "No") {
                _options = Options.no;
              }
            }
            //
            if (type == "employ") {
              if (selectedQuestions[index]["answer"] == "Self Employed") {
                _eOptions = EmployeeOptions.selfEmployed;
              } else if (selectedQuestions[index]["answer"] == "Salaried") {
                _eOptions = EmployeeOptions.salaried;
              }
            }
            //
            return GestureDetector(
              onTap: () {
                hideKeyboard();
              },
              child: Card(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${index + 1}. " + question["question"],
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600)),
                      SizedBox(
                        height: 15,
                      ),
                      type == "text"
                          ? TextField(
                              controller: _controller,
                              keyboardType: TextInputType.multiline,
                              maxLength: 600,
                              maxLines: null,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Write here...',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: (value) {
                                selectedQuestions[index]["answer"] = value;
                              },
                            )
                          : type == "option"
                              ? Column(
                                  children: [
                                    RadioListTile(
                                      dense: true,
                                      activeColor: primaryColor,
                                      contentPadding: EdgeInsets.all(0),
                                      title: Text(
                                        OptionsHelper.getTitle(Options.yes),
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      value: Options.yes,
                                      groupValue: _options,
                                      onChanged: (Options value) {
                                        hideKeyboard();
                                        setState(() {
                                          _options = value;
                                        });
                                        selectedQuestions[index]["answer"] =
                                            OptionsHelper.getTitle(Options.yes);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      activeColor: primaryColor,
                                      contentPadding: EdgeInsets.all(0),
                                      title: Text(
                                        OptionsHelper.getTitle(Options.no),
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      value: Options.no,
                                      groupValue: _options,
                                      onChanged: (Options value) {
                                        hideKeyboard();
                                        setState(() {
                                          _options = value;
                                        });
                                        selectedQuestions[index]["answer"] =
                                            OptionsHelper.getTitle(Options.no);
                                      },
                                    )
                                  ],
                                )
                              : type == "employ"
                                  ? Column(
                                      children: [
                                        RadioListTile(
                                          dense: true,
                                          activeColor: primaryColor,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            EmployeeOptionsHelper.getTitle(
                                                EmployeeOptions.selfEmployed),
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          value: EmployeeOptions.selfEmployed,
                                          groupValue: _eOptions,
                                          onChanged: (EmployeeOptions value) {
                                            hideKeyboard();
                                            selectedQuestions[index]["answer"] =
                                                EmployeeOptionsHelper.getTitle(
                                                    EmployeeOptions
                                                        .selfEmployed);
                                            setState(() {
                                              _eOptions = value;
                                            });
                                          },
                                        ),
                                        RadioListTile(
                                          dense: true,
                                          activeColor: primaryColor,
                                          contentPadding: EdgeInsets.all(0),
                                          title: Text(
                                            EmployeeOptionsHelper.getTitle(
                                                EmployeeOptions.salaried),
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          value: EmployeeOptions.salaried,
                                          groupValue: _eOptions,
                                          onChanged: (EmployeeOptions value) {
                                            hideKeyboard();
                                            selectedQuestions[index]["answer"] =
                                                EmployeeOptionsHelper.getTitle(
                                                    EmployeeOptions.salaried);
                                            setState(() {
                                              _eOptions = value;
                                            });
                                          },
                                        )
                                      ],
                                    )
                                  : Container()
                    ],
                  ),
                ),
              ),
            );
          }
        },
      )),
    );
  }

  bool checkFormFilled() {
    final count = selectedQuestions
        .where((element) => element["answer"] == "" || element["answer"] == null)
        .toList()
        .length;
    if (count > 0) {
      return false;
    }
    return true;
  }
}
