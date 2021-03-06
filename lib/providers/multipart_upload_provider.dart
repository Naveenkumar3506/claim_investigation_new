import 'dart:convert';
import 'dart:io';
import 'package:claim_investigation/base/base_provider.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/service/api_constants.dart';
import 'package:claim_investigation/util/app_enum.dart';

class MultiPartUploadProvider extends BaseProvider {
  //image upload
  Future uploadFile(File file, MimeMediaType mimeType, CaseModel caseModel,
      String uploadType) async {
    try {
      final response = await super.apiClient.uploadFiles(
          path: ApiConstant.API_FILE_UPLOAD,
          file: file,
          mimeType: mimeType,
          caseModel: caseModel,
          uploadType: uploadType);
      if (response.statusCode == 200) {
        String body = await response.stream.bytesToString();
        final jsonResponse = json.decode(body);
        if (jsonResponse.containsKey('Success') &&
            jsonResponse['Success'] == true) {
          return jsonResponse['Data']['Url'];
        } else {
          // if (jsonResponse.containsKey('Message')) {
          //   return AppException(jsonResponse['Message']);
          // } else {
          //   return AppException(
          //       'Oops, something went wrong. Please try again later.');
          // }
        }
      } else {
        return null;
      }
    } catch (e) {
      print(e);
    }
  }
}
