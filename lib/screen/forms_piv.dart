import 'dart:convert';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/screen/forms_piv_others.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_toast.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PIVFormsScreen extends BasePage {
  static const routeName = '/pivFormsScreen';

  @override
  _PIVFormsScreenState createState() => _PIVFormsScreenState();
}

class _PIVFormsScreenState extends BaseState<PIVFormsScreen> {
  bool isTypeSelected = false;
  List<PIVScenarios> _selectedScenarios = [];
  List questions = [];
  int questionIndex = 0;
  Map<String, dynamic> answers = {};
  String questionHeader = "";

  @override
  void initState() {
    Future.delayed(Duration(milliseconds: 50)).then((value) => getQuestions());
    if (Get.arguments != null) {
      answers = Get.arguments;
      answers.keys.forEach((e) {
        if (e != "Others") {
          setState(() {
            _selectedScenarios.add(PIVScenarioHelper.getScenarioFromString(e));
          });
        }
      });
      setState(() {});
    }
    super.initState();
  }

  getQuestions() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString("assets/images/piv_questions.json");
    final aaa = Map<String, dynamic>.from(json.decode(data));
    if (questionIndex < _selectedScenarios.length) {
      if (answers[
              PIVScenarioHelper.getTitle(_selectedScenarios[questionIndex])] !=
          null) {
        questions = answers[
            PIVScenarioHelper.getTitle(_selectedScenarios[questionIndex])];
      } else {
        questions =
            aaa[PIVScenarioHelper.getTitle(_selectedScenarios[questionIndex])];
      }
      questionHeader =
          PIVScenarioHelper.getTitle(_selectedScenarios[questionIndex]);
    } else {
      if (answers["Others"] != null) {
        questions = answers["Others"];
      } else {
        questions = aaa["Others"];
      }
      questionHeader = "Others";
    }
    setState(() {});
  }

  Future<DateTime> _selectDate(BuildContext context) async {
    DateTime newSelectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: primaryColor,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Colors.blue[500],
            ),
            child: child,
          );
        });

    if (newSelectedDate != null) {
      return newSelectedDate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PIV Form"),
      ),
      body: SafeArea(
        child: isTypeSelected
            ? ListView.builder(
                itemCount: questions.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == questions.length) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            // color: primaryColor,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  primaryColor),
                            ),
                            onPressed: () async {
                              hideKeyboard();
                              setState(() {
                                if (questionIndex > 0) {
                                  questionIndex--;
                                  answers[questionHeader] = questions;
                                  getQuestions();
                                } else {
                                  questionIndex = 0;
                                  answers[questionHeader] = questions;
                                  isTypeSelected = false;
                                }
                              });
                            },
                            child: Text(
                              'Prev',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            // color: primaryColor,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  primaryColor),
                            ),
                            onPressed: () async {
                              hideKeyboard();
                              if (!isTypeSelected) {
                                isTypeSelected = true;
                                getQuestions();
                              } else {
                                if (questionIndex < _selectedScenarios.length) {
                                  if (checkFormFilled()) {
                                    questionIndex++;
                                    getQuestions();
                                    answers[questionHeader] = questions;
                                  } else {
                                    AppToast.toast(
                                      'Please answer all the questions.',
                                    );
                                  }
                                } else {
                                  if (checkFormFilled()) {
                                    answers[questionHeader] = questions;
                                    Provider.of<ClaimProvider>(context,
                                            listen: false)
                                        .pivAnswers = answers;

                                    showLoadingDialog();
                                    Provider.of<ClaimProvider>(context,
                                        listen: false).addPIVQuestionarie(12).then((value){
                                      Provider.of<ClaimProvider>(context,
                                          listen: false)
                                          .pivAnswers = null;
                                      Navigator.pop(context);
                                      Navigator.pop(context, "done");
                                    });

                                  }
                                }
                              }
                            },
                            child: Text(
                              questionIndex == _selectedScenarios.length
                                  ? "Submit"
                                  : 'Next',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final question = questions[index];
                    final type = question["type"];
                    TextEditingController _controller = TextEditingController();
                    _controller.text = questions[index]["answer"] ?? "";
                    TextEditingController _dateController =
                        TextEditingController();
                    _dateController.text = questions[index]["answer"] ?? "";
                    print(index.toString());
                    Options _options;
                    EmployeeOptions _eOptions;
                    if (type == "option") {
                      if (questions[index]["answer"] == "Yes") {
                        _options = Options.yes;
                      } else if (questions[index]["answer"] == "No") {
                        _options = Options.no;
                      }
                    }
                    if (type == "employ") {
                      if (questions[index]["answer"] == "Self Employed") {
                        _eOptions = EmployeeOptions.selfEmployed;
                      } else if (questions[index]["answer"] == "Salaried") {
                        _eOptions = EmployeeOptions.salaried;
                      }
                    }
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
                                      maxLength: 200,
                                      maxLines: null,
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: 'Write here...',
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        questions[index]["answer"] = value;
                                      },
                                    )
                                  : type == "date"
                                      ? TextField(
                                          controller: _dateController,
                                          readOnly: true,
                                          maxLines: 1,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            hintText: 'Select date',
                                            hintStyle:
                                                TextStyle(color: Colors.grey),
                                          ),
                                          onTap: () async {
                                            hideKeyboard();
                                            final selectedDate =
                                                await _selectDate(context);
                                            if (selectedDate != null) {
                                              setState(() {
                                                questions[index]["answer"] =
                                                    DateFormat("dd-MM-yyyy")
                                                        .format(selectedDate);
                                              });
                                            }
                                          },
                                        )
                                      : type == "option"
                                          ? Column(
                                              children: [
                                                RadioListTile(
                                                  dense: true,
                                                  activeColor: primaryColor,
                                                  contentPadding:
                                                      EdgeInsets.all(0),
                                                  title: Text(
                                                    OptionsHelper.getTitle(
                                                        Options.yes),
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                  value: Options.yes,
                                                  groupValue: _options,
                                                  onChanged: (Options value) {
                                                    hideKeyboard();
                                                    setState(() {
                                                      _options = value;
                                                    });
                                                    questions[index]["answer"] =
                                                        OptionsHelper.getTitle(
                                                            Options.yes);
                                                  },
                                                ),
                                                RadioListTile(
                                                  dense: true,
                                                  activeColor: primaryColor,
                                                  contentPadding:
                                                      EdgeInsets.all(0),
                                                  title: Text(
                                                    OptionsHelper.getTitle(
                                                        Options.no),
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                  value: Options.no,
                                                  groupValue: _options,
                                                  onChanged: (Options value) {
                                                    hideKeyboard();
                                                    setState(() {
                                                      _options = value;
                                                    });
                                                    questions[index]["answer"] =
                                                        OptionsHelper.getTitle(
                                                            Options.no);
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
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                      title: Text(
                                                        EmployeeOptionsHelper
                                                            .getTitle(
                                                                EmployeeOptions
                                                                    .selfEmployed),
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      value: EmployeeOptions
                                                          .selfEmployed,
                                                      groupValue: _eOptions,
                                                      onChanged:
                                                          (EmployeeOptions
                                                              value) {
                                                        hideKeyboard();
                                                        questions[index]
                                                                ["answer"] =
                                                            EmployeeOptionsHelper
                                                                .getTitle(
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
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                      title: Text(
                                                        EmployeeOptionsHelper
                                                            .getTitle(
                                                                EmployeeOptions
                                                                    .salaried),
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      value: EmployeeOptions
                                                          .salaried,
                                                      groupValue: _eOptions,
                                                      onChanged:
                                                          (EmployeeOptions
                                                              value) {
                                                        hideKeyboard();
                                                        questions[index]
                                                                ["answer"] =
                                                            EmployeeOptionsHelper
                                                                .getTitle(
                                                                    EmployeeOptions
                                                                        .salaried);
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
                })
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(children: [
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Please select radio buttons as per the scenario",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    ),
                    ...PIVScenarios.values.map((scenario) {
                      return CheckboxListTile(
                          value: _selectedScenarios.contains(scenario),
                          title: Text(
                            PIVScenarioHelper.getTitle(scenario),
                            style: TextStyle(color: Colors.black),
                          ),
                          onChanged: (value) {
                            if (_selectedScenarios.contains(scenario)) {
                              _selectedScenarios.remove(scenario);
                            } else {
                              _selectedScenarios.add(scenario);
                            }
                            setState(() {});
                          });
                    }),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            // color: primaryColor,
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.grey),
                            ),
                            onPressed: () {},
                            child: Text(
                              'Prev',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            // color: primaryColor,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  primaryColor),
                            ),
                            onPressed: () async {
                              hideKeyboard();
                              if (!isTypeSelected) {
                                isTypeSelected = true;
                                getQuestions();
                              } else {}
                            },
                            child: Text(
                              'Next',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }

  bool checkFormFilled() {
    final count = questions
        .where(
            (element) => element["answer"] == "" || element["answer"] == null)
        .toList()
        .length;
    if (count > 0) {
      return false;
    }
    return true;
  }
}
