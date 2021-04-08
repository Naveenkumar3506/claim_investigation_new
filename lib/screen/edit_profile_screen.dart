import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/providers/multipart_upload_provider.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/widgets/app_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends BasePage {
  static const routeName = '/editProfileScreen';

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends BaseState<EditProfileScreen> {
  final _editFormKey = GlobalKey<FormState>();
  final _userNameTextController = TextEditingController();
  final _fullNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();
  File _imageFile;
  UserModel _userModel;
  bool _isLoading = false;

  @override
  void initState() {
    if (pref.user != null) {
      _userModel = pref.user;
      _userNameTextController.text = _userModel.username;
      _fullNameTextController.text = _userModel.fullName;
      _emailTextController.text = _userModel.userEmail;
      _phoneTextController.text = _userModel.mobileNumber;
    }
    super.initState();
  }

  bool _validateInputs() {
    if (_editFormKey.currentState.validate()) {
      print('Form is valid');
      _editFormKey.currentState.save();
      return true;
    } else {
      print('Form is invalid');
      return false;
    }

  }

  updateProfile() async {
    if (_validateInputs()) {
      try {
        setState(() {
          _isLoading = true;
        });
        await Provider.of<MultiPartUploadProvider>(
            context,
            listen: false)
            .uploadProfileFile(_imageFile, MimeMediaType.image, _userModel)
            .then((success) {
          setState(() {
            _isLoading = false;
          });
          if (success) {
            showSuccessToast('Profile updated successfully');
            pref.user = _userModel;
          } else {
            showErrorToast('Oops, something went wrong. Please try later');
          }
        });
      } catch (error) {
        Navigator.pop(context);
        setState(() {
          _isLoading = false;
        });
        print("mmm ${error.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: SingleChildScrollView(
          child: SafeArea(
            child: Form(
              key: _editFormKey,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        imagePickerDialog(() async {
                          //camera
                          await getImageFile(ImageSource.camera)
                              .then((value) async {
                            if (value != null) {
                              setState(() {
                                _imageFile = value;
                              });
                            }
                          });
                        }, () async {
                          //gallery
                          await getImageFile(ImageSource.gallery)
                              .then((value) async {
                            if (value != null) {
                              setState(() {
                                _imageFile = value;
                              });
                            }
                          });
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 35,
                        child: _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _imageFile,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                        backgroundImage: (pref.user.userImage == null ||
                                pref.user.userImage == "")
                            ? AssetImage(
                                'assets/images/ic_profile_placeholder.jpg')
                            : CachedNetworkImageProvider(pref.user.userImage),
                      ),
                    ),
                    SizedBox(height: 20),
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
                    AppFormTextField(
                      hintText: 'Enter your full name',
                      hintLabel: 'Full name',
                      controller: _fullNameTextController,
                      ctx: context,
                      focusNode: _emailNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onSubmit: (_) {
                        FocusScope.of(context).requestFocus(_passwordNode);
                      },
                      validator: (email) {
                        if (email == "") {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    AppFormTextField(
                      hintText: 'Enter your email id',
                      hintLabel: 'Email Id',
                      controller: _emailTextController,
                      ctx: context,
                      focusNode: _emailNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onSubmit: (_) {
                        FocusScope.of(context).requestFocus(_passwordNode);
                      },
                      validator: (email) {
                        if (email == "") {
                          return 'Please enter email-id';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    AppFormTextField(
                      hintText: 'Enter your phone number',
                      hintLabel: 'Phone Number',
                      controller: _phoneTextController,
                      ctx: context,
                      focusNode: _emailNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onSubmit: (_) {
                        FocusScope.of(context).requestFocus(_passwordNode);
                      },
                      validator: (email) {
                        if (email == "") {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.maxFinite,
                      child: CupertinoButton(
                        color: Theme.of(context).primaryColor,
                        child: Text(
                          'Update profile',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => updateProfile(),
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
    );
  }
}
