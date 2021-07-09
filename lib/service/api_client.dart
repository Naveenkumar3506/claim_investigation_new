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
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
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
      dynamic body,
      bool withAuth = true,
      File file}) async {
    Map<String, String> headers = Map();
    headers[HttpHeaders.contentTypeHeader] = "application/json";
    if (withAuth) {}

    /// Check internet connection
    // var connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult == ConnectivityResult.none) {
    //   return Left(AppException('Please check your internet connection'));
    // }

    var responseData;
    final url = ApiConstant.API_BASE_URL + path;
    debugPrint(' $_tagRequest  $method   $url \n $headers');
    debugPrint(file == null ? '  $jsonEncode($body)' : 'File upload');

    try {
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
            responseData = await http.patch(url,
                headers: headers, body: json.encode(body));
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
        Provider.of<AuthProvider>(SizeConfig.cxt, listen: false)
            .clearUserData();
        // Get.offAllNamed(LoginScreen.routeName);
        showErrorToast('Your login session expired. Please login again');
      } else {
       // return Left(AppException('Oops, something went wrong. Please try again later.'));
       // return Left(Exception('Response Code: ${responseData.statusCode}- Service Unavailable!'));
        throw FetchDataException('Oops, something went wrong. Please try again later.');
      }
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return Left(AppException(
        'Oops, something went wrong. Please try again later.'));
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
    request.fields['uploadType'] = uploadType;
    request.fields['latitude'] = caseModel.latitude;
    request.fields['longitude'] = caseModel.longitude;
    request.fields['caseId'] = caseModel.caseId.toString();
    request.fields['version'] = ApiConstant.API_VERSION_NUM;

    if (file != null) {
      if (mimeType == MimeMediaType.image) {
        request.files.add(
          await http.MultipartFile.fromPath('uploadedFile', file.path).timeout(Duration(minutes: 10)),
          // await http.MultipartFile.fromPath('uploadedFile', file.path,contentType: http_parser.MediaType('image', 'jpeg')),
        );
      } else if (mimeType == MimeMediaType.video) {
        request.files.add(
          await http.MultipartFile.fromPath('uploadedFile', file.path).timeout(Duration(minutes: 60)),
          //  await http.MultipartFile.fromPath('uploadedFile', file.path, contentType: new http_parser.MediaType('Video', 'mpeg')),
        );
      } else if (mimeType == MimeMediaType.pdf) {
        request.files.add(
          await http.MultipartFile.fromPath('uploadedFile', file.path,
              contentType: new http_parser.MediaType('pdf', 'pdf')).timeout(Duration(minutes: 10)),
        );
      } else if (mimeType == MimeMediaType.audio) {
        request.files.add(
          await http.MultipartFile.fromPath('uploadedFile', file.path).timeout(Duration(minutes: 10)),
          //  await http.MultipartFile.fromPath('uploadedFile', file.path, contentType: new http_parser.MediaType('Audio', 'mpeg')),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('uploadedFile', file.path,
              contentType: new http_parser.MediaType('excel', 'excel')).timeout(Duration(minutes: 10)),
        );
      }
    }

    request.headers.addAll(headers);
    request.persistentConnection = true;

    final url = request.url;
    debugPrint(' $_tagRequest  $url \n $headers');
    debugPrint('$jsonEncode(${request.fields.toString()})');

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
    request.fields['version'] = ApiConstant.API_VERSION_NUM;

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

    final url = ApiConstant.API_BASE_URL + path;
    debugPrint(' $_tagRequest  $url \n $headers');
    debugPrint(file == null
        ? '  $jsonEncode(${request.fields.toString()})'
        : 'File upload');

    final res = await request.send().then((response) {
      return response;
    }).catchError((e) {
      print(e);
      return Left(AppException(e.toString()));
    });
    return res;
  }

  static var httpClient = new HttpClient();

  Future<File> downloadFile(String url, String filename) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = Platform.isAndroid
        ? await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_DOWNLOADS)
        : (await getApplicationDocumentsDirectory()).path;

    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}


//
class CustomException implements Exception {
  final _message;
  final _prefix;

  CustomException([this._message, this._prefix]);

  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends CustomException {
  FetchDataException([String message])
      : super(message, "");
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends CustomException {
  InvalidInputException([String message]) : super(message, "Invalid Input: ");
}