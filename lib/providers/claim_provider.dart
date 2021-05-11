import 'dart:io';

import 'package:claim_investigation/base/base_provider.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'package:claim_investigation/service/api_client.dart';
import 'package:claim_investigation/service/api_constants.dart';
import 'package:claim_investigation/storage/db_helper.dart';
import 'package:claim_investigation/util/app_exception.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/app_log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClaimProvider extends BaseProvider {
  List<CaseModel> _listCases = [];
  int caseListPageNumber = 1;
  int fetchDataSize = 10;
  bool _isLoadMore = false;
  ScrollController scrollController;
  ReportModel _reportModel;

  ReportModel get reportModel => _reportModel;

  set reportModel(ReportModel value) {
    _reportModel = value;
    notifyListeners();
  }

  List<CaseModel> get listCases => _listCases;

  set listCases(List<CaseModel> value) {
    _listCases = value;
    notifyListeners();
  }

  bool get isLoadMore => _isLoadMore;

  set isLoadMore(bool value) {
    _isLoadMore = value;
    notifyListeners();
  }

  Future<ReportModel> getDashBoard() async {
    isLoading = true;
    await super
        .apiClient
        .callWebService(
            path: ApiConstant.API_DASHBOARD_DETAIL,
            method: ApiMethod.POST,
            body: {
              'username': pref.user.username,
            },
            withAuth: false)
        .then((response) {
      isLoading = false;
      return response.fold((l) {
        AppLog.print('left----> ' + l.toString());
        showErrorToast(l.toString());
        return null;
      }, (r) async {
        AppLog.print('right----> ' + r.toString());
        final reportModel = ReportModel.fromJson(r);
        await DBHelper.saveReport(reportModel);
        return reportModel;
      });
    }, onError: (error) {
      isLoading = false;
      showErrorToast(error.toString());
      throw error;
    });
  }

  Future getCaseList(bool isRefresh) async {
    if (isRefresh) {
      caseListPageNumber = 1;
    }
    //
    if (caseListPageNumber > 1) {
      isLoadMore = true;
    } else {
      isLoading = true;
    }

    await super
        .apiClient
        .callWebService(
            path: ApiConstant.API_GET_CASE_LIST,
            method: ApiMethod.POST,
            body: {
              "username": pref.user.username,
              "pageNum": caseListPageNumber,
              "pagesize": fetchDataSize
            },
            withAuth: false)
        .then((response) async {
      isLoading = false;
      isLoadMore = false;
      response.fold((l) {
        AppLog.print('left----> ' + l.toString());
        showErrorToast(l.toString());
      }, (r) async {
        AppLog.print('right----> ' + r.toString());
        final parsed = r.cast<Map<String, dynamic>>();
        List<CaseModel> arrayCases =
            parsed.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
        if (arrayCases.isNotEmpty) {
          if (isRefresh) {
            listCases.clear();
            if (scrollController != null) {
              // scrollController.animateTo(
              //   0.0,
              //   curve: Curves.easeOut,
              //   duration: const Duration(milliseconds: 300),
              // );
            }
          }
          listCases.addAll(arrayCases);
          await DBHelper.saveCases(listCases);
          caseListPageNumber += 1;
        } else {
          showSuccessToast(isLoadMore ? 'you are done' : 'No Cases Found');
        }
      });
    }, onError: (error) {
      isLoading = false;
      isLoadMore = false;
      throw error;
    });
  }

  Future<bool> submitReport(CaseModel caseModel) async {
    showLoadingIndicator();
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_UPDATE_CASE_DETAILS,
        method: ApiMethod.POST,
        body: {
          'username': pref.user.username,
          'case_description': caseModel.caseDescription,
          'longitude': caseModel.longitude,
          'latitude': caseModel.latitude,
          'capturedDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'caseid': caseModel.caseId,
          'remarks': caseModel.newRemarks
        },
        withAuth: false);
    hideLoadingIndicator();
    return response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      return false;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      return true;
    });
  }

  Future<List<CaseModel>> getNewCaseList(bool isRefresh, String type) async {
    if (isRefresh) {
      caseListPageNumber = 1;
      listCases.clear();
    }
    //
    if (caseListPageNumber > 1) {
      isLoadMore = true;
    } else {
      isLoading = true;
    }

    String path = "";
    if (type == "PIV/PRV/LIVE count") {
      path = ApiConstant.API_GET_CASE_INTIMATION_LIST;
    } else if (type == "New") {
      path = ApiConstant.API_GET_NEW_CASE_LIST;
    } else if (type == "Claim Document Pickup") {
      path = ApiConstant.API_GET_CDP_CASE_LIST;
    } else if (type == "Closed") {
      path = ApiConstant.API_GET_CLOSED_CASE_LIST;
    } else {
      path = ApiConstant.API_GET_CASE_SUBMITTED_LIST;
    }

    final response = await super.apiClient.callWebService(
        path: path,
        method: ApiMethod.POST,
        body: {
          "username": pref.user.username,
          "pageNum": caseListPageNumber,
          "pagesize": fetchDataSize
        },
        withAuth: false);

    isLoading = false;
    isLoadMore = false;

    return response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      return listCases;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      final parsed = r.cast<Map<String, dynamic>>();
      List<CaseModel> arrayCases =
          parsed.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
      if (arrayCases.isNotEmpty) {
        if (isRefresh) {
          listCases.clear();
          if (scrollController != null) {
            // scrollController.animateTo(
            //   0.0,
            //   curve: Curves.easeOut,
            //   duration: const Duration(milliseconds: 300),
            // );
          }
        }
        listCases.addAll(arrayCases);
        caseListPageNumber += 1;
      } else {
        showSuccessToast(isLoadMore ? 'you are done' : 'No Cases Found');
      }
      return listCases;
    });
  }

  clearData() {
    listCases.clear();
    caseListPageNumber = 1;
  }

  Future<File> downloadFile(String url, String filename) async {
    final file = await apiClient.downloadFile(url, filename);
    return file;
  }

  Future updateLocation(String lat, String long) async {
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_LOCATION_UPDATE,
        method: ApiMethod.POST,
        body: {
          "username": pref.user.username,
          "latitude": caseListPageNumber,
          "longitude": fetchDataSize
        },
        withAuth: false);

    response.fold((l) {
      AppLog.print('left----> ' + l.toString());
    }, (r) {
      AppLog.print('right----> ' + r.toString());
    });
  }

  // database
  Future getCasesFromDB() async {
    final arrayCases = await DBHelper.getAllCases();
    listCases = arrayCases;
  }

  Future<ReportModel> getDashBoardFromDB() async {
    reportModel = await DBHelper.getReport();
    return reportModel;
  }
}
