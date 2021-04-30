import 'dart:convert';
import 'dart:io';
import 'package:claim_investigation/base/base_provider.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/service/api_constants.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:flutter/material.dart';

class MultiPartUploadProvider extends BaseProvider {
  //image upload
  Future<bool> uploadFile(File file, MimeMediaType mimeType,
      CaseModel caseModel, String uploadType) async {
    try {
      final response = await super.apiClient.uploadFiles(
          path: ApiConstant.API_FILE_UPLOAD,
          file: file,
          mimeType: mimeType,
          caseModel: caseModel,
          uploadType: uploadType);
      String body = await response.stream.bytesToString();
      final jsonResponse = json.decode(body);
      print(jsonResponse.toString());
      if (response.statusCode == 200) {
        if (jsonResponse.containsKey('data') &&
            jsonResponse['data'] == "File uploaded successfully") {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> uploadProfileFile(
      File file, MimeMediaType mimeType, UserModel userModel) async {
    try {
      final response = await super.apiClient.uploadProfileFiles(
          path: ApiConstant.API_PROFILE_UPLOAD,
          file: file,
          mimeType: mimeType,
          userModel: userModel);
      String body = await response.stream.bytesToString();
      final jsonResponse = json.decode(body);
      debugPrint(jsonResponse.toString());
      if (response.statusCode == 200) {
        if (jsonResponse.containsKey('data') &&
            jsonResponse['data'] == "Candidate Details updated successfully") {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
