import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/user_model.dart';
import 'package:claim_investigation/providers/auth_provider.dart';
import 'package:claim_investigation/storage/app_pref.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_exception.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:dartz/dartz.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

import 'api_constants.dart';

enum ApiMethod { GET, POST, PUT, DELETE, UPDATE, MULTIPART }

class ApiClient {
  AppSharedPref _pref = getIt<AppSharedPref>();

  final String _tagRequest = '====== Request =====>';
  final String _tagResponse = '====== Response =====>';

  Future<Either<Exception, dynamic>> callWebService(
      {@required String path,
      Encoding encoding,
      @required ApiMethod method,
      Map<String, dynamic> body,
      bool withAuth = true,
      File file}) async {
    Map<String, String> headers = Map();
    headers[HttpHeaders.contentTypeHeader] = "application/json";
    if (withAuth) {}

    /// Check internet connection
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return Left(AppException('Please check your internet connection'));
    }

    var responseData;
    final url = ApiConstant.API_BASE_URL + path;
    debugPrint(' $_tagRequest  $method   $url \n $headers');
    debugPrint(file == null ? '  $jsonEncode($body)' : 'File upload');

    switch (method) {
      case ApiMethod.GET:
        {
          responseData = await http.get(url, headers: headers);
        }
        break;
      case ApiMethod.POST:
        {
          responseData =
              await http.post(url, headers: headers, body: json.encode(body));
        }
        break;
      case ApiMethod.UPDATE:
        {
          responseData =
              await http.patch(url, headers: headers, body: json.encode(body));
          break;
        }
      case ApiMethod.PUT:
        {
          responseData =
              await http.put(url, headers: headers, body: json.encode(body));
          break;
        }
      case ApiMethod.DELETE:
        {
          responseData = await http.delete(
            url,
            headers: headers,
          );
        }
        break;
      case ApiMethod.MULTIPART:
        {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
              ApiConstant.API_BASE_URL + ApiConstant.API_FILE_UPLOAD,
            ),
          );
          request.files.add(
            await http.MultipartFile.fromPath('file', file.path,
                contentType: http_parser.MediaType('image', '')),
          );
          request.headers.addAll(headers);
          request.persistentConnection = true;

          await request.send().then((response) async {
            // listen for response
            if (response.statusCode == 200) {
              response.stream.transform(utf8.decoder).listen((value) {
                final jsonResponse = json.decode(value);
                print(jsonResponse);
                if (jsonResponse.containsKey('data') &&
                    jsonResponse['data'] != null &&
                    jsonResponse['data'].toString() != 'null') {
                  return Right(jsonResponse['data']);
                } else {
                  if (jsonResponse.containsKey('status')) {
                    return Left(AppException(jsonResponse['status']));
                  } else {
                    return Left(AppException(
                        'Oops, something went wrong. Please try again later.'));
                    // return Left(Exception('Response Code: ${responseData.statusCode}- Service Unavailable!'));
                  }
                }
              });
            }
          }).catchError((e) {
            print(e);
          });
        }
        break;
    }

    ///
    debugPrint(
      '$_tagResponse ${responseData.statusCode} - $url \n ${responseData.body}',
    );
    if (responseData.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(responseData.body);
      if (jsonResponse is List<dynamic>) {
        return Right(jsonResponse);
      } else if (jsonResponse.containsKey('data') &&
          jsonResponse['data'] != null &&
          jsonResponse['data'].toString() != 'null') {
        return Right(jsonResponse['data']);
      } else {
        if (jsonResponse.containsKey('status')) {
          return Left(AppException(jsonResponse['status']));
        } else {
          return Left(AppException(
              'Oops, something went wrong. Please try again later.'));
          // return Left(Exception('Response Code: ${responseData.statusCode}- Service Unavailable!'));
        }
      }
    } else if (responseData.statusCode == HttpStatus.unauthorized) {
      _pref.clearUserData();
      Provider.of<AuthProvider>(SizeConfig.cxt, listen: false).clearUserData();
      // Get.offAllNamed(LoginScreen.routeName);
      showErrorToast('Your login session expired. Please login again');
    } else {
      return Left(
          AppException('Oops, something went wrong. Please try again later.'));
      return Left(Exception(
          'Response Code: ${responseData.statusCode}- Service Unavailable!'));
    }
  }

  Future uploadFiles(
      {@required String path,
      Encoding encoding,
      File file,
      MimeMediaType mimeType,
      CaseModel caseModel,
      String uploadType}) async {
    Map<String, String> headers = Map();
    headers[HttpHeaders.contentTypeHeader] = "application/json";

    /// Check internet connection
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return Left(AppException('Please check your internet connection'));
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConstant.API_BASE_URL + ApiConstant.API_FILE_UPLOAD,
      ),
    );

    request.fields['username'] = _pref.user.username;
    request.fields['uploadType'] = 'image';
    request.fields['latitude'] = caseModel.latitude;
    request.fields['longitude'] = caseModel.longitude;
    request.fields['caseid'] = caseModel.caseId.toString();

    if (mimeType == MimeMediaType.image) {
      request.files.add(
        await http.MultipartFile.fromPath('uploadedFile', file.path),
       // await http.MultipartFile.fromPath('uploadedFile', file.path,contentType: http_parser.MediaType('image', 'jpeg')),
      );
    } else if (mimeType == MimeMediaType.video) {
      request.files.add(
        await http.MultipartFile.fromPath('uploadedFile', file.path,
            contentType: new http_parser.MediaType('video', 'mp4')),
      );
    }

    request.headers.addAll(headers);
    request.persistentConnection = true;

    final res = await request.send().then((response) {
      return response;
    }).catchError((e) {
      print(e);
      return Left(AppException(e.toString()));
    });
    return res;
  }

  Future uploadProfileFiles(
      {@required String path,
        Encoding encoding,
        File file,
        MimeMediaType mimeType,
        UserModel userModel}) async {
    Map<String, String> headers = Map();
    headers[HttpHeaders.contentTypeHeader] = "application/json";

    /// Check internet connection
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return Left(AppException('Please check your internet connection'));
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConstant.API_BASE_URL + ApiConstant.API_PROFILE_UPLOAD,
      ),
    );

    request.fields['username'] = userModel.username;
    request.fields['full_name'] = userModel.fullName;
    request.fields['emailId'] = userModel.userEmail;
    request.fields['contactNumber'] = userModel.mobileNumber;

    if (file != null) {
      if (mimeType == MimeMediaType.image) {
        request.files.add(
          await http.MultipartFile.fromPath('updatePhoto', file.path),
          // await http.MultipartFile.fromPath('uploadedFile', file.path,contentType: http_parser.MediaType('image', 'jpeg')),
        );
      } else if (mimeType == MimeMediaType.video) {
        request.files.add(
          await http.MultipartFile.fromPath('updatePhoto', file.path,
              contentType: new http_parser.MediaType('video', 'mp4')),
        );
      }
    }

    request.headers.addAll(headers);
    request.persistentConnection = true;

    final res = await request.send().then((response) {
      return response;
    }).catchError((e) {
      print(e);
      return Left(AppException(e.toString()));
    });
    return res;
  }
}
