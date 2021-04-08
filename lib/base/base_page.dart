import 'dart:io';

import 'package:claim_investigation/storage/app_pref.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'base_provider.dart';

abstract class BasePage extends StatefulWidget {
  BasePage({Key key}) : super(key: key);
}

abstract class BaseState<Page extends BasePage> extends State<Page> {
  AppSharedPref pref = getIt<AppSharedPref>();
  AppHelper appHelper = getIt<AppHelper>();

  hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  imagePickerDialog(Function onCamera, Function onGallery) {
    Get.bottomSheet(
      Wrap(
        children: [
          Container(
            color: Colors.white,
            height: SizeConfig.screenHeight * .3,
            width: SizeConfig.screenWidth,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Choose image using',
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 15,
                ),
                FlatButton.icon(
                  icon: Icon(Icons.photo_camera),
                  label: Text('Camera'),
                  onPressed: () {
                    Navigator.pop(context);
                    onCamera();
                  },
                ),
                Divider(
                  height: 3,
                ),
                FlatButton.icon(
                  icon: Icon(Icons.photo_album),
                  label: Text('Gallery'),
                  onPressed: () {
                    Navigator.pop(context);
                    onGallery();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  videoPickerDialog(Function onCamera, Function onGallery) {
    Get.bottomSheet(
      Wrap(
        children: [
          Container(
            color: Colors.white,
            height: SizeConfig.screenHeight * .3,
            width: SizeConfig.screenWidth,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Choose video using',
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 15,
                ),
                FlatButton.icon(
                  icon: Icon(Icons.photo_camera),
                  label: Text('Camera'),
                  onPressed: () {
                    Navigator.pop(context);
                    onCamera();
                  },
                ),
                Divider(
                  height: 3,
                ),
                FlatButton.icon(
                  icon: Icon(Icons.photo_album),
                  label: Text('Gallery'),
                  onPressed: () {
                    Navigator.pop(context);
                    onGallery();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<File> getImageFile(ImageSource source) async {
    final picker = ImagePicker();
    var tempFile = await picker.getImage(source: source);
    if (tempFile != null) {
      File croppedFile = await ImageCropper.cropImage(
          sourcePath: tempFile.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
          ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: IOSUiSettings(
            minimumAspectRatio: 1.0,
          ));
      var resultAfterCompress = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path, tempFile.path,
          quality: 60);
      return resultAfterCompress;
    }
    return null;
  }

  Future<File> getVideoFile(ImageSource source) async {
    final picker = ImagePicker();
    final tempFile = await picker.getVideo(
        source: source, maxDuration: const Duration(minutes: 1));
    if (tempFile != null) {
      debugPrint("${File(tempFile.path)}");
      return File(tempFile.path);
    }
    return null;
  }
}

mixin BasicPage<Page extends BasePage> on BaseState<Page> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BaseProvider>(
      builder: (BuildContext context, BaseProvider value, Widget child) {
        return ModalProgressHUD(
          inAsyncCall: value.isLoading,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              appBar: appBar(),
              drawer: drawer(),
              body: SafeArea(
                child: body(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget appBar() {
    return null;
  }

  Widget drawer() {
    return null;
  }

  Widget body();
}
