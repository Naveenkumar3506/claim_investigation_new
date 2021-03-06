import 'package:claim_investigation/base/base_provider.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'package:claim_investigation/service/api_client.dart';
import 'package:claim_investigation/service/api_constants.dart';
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
    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_DASHBOARD_DETAIL,
        method: ApiMethod.POST,
        body: {
          'username': pref.user.username,
        },
        withAuth: false);
    isLoading = false;
    return response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
      return null;
    }, (r) {
      AppLog.print('right----> ' + r.toString());
      return ReportModel.fromJson(r);
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

    final response = await super.apiClient.callWebService(
        path: ApiConstant.API_GET_CASE_LIST,
        method: ApiMethod.POST,
        body: {
          "username": pref.user.username,
          "pageNum": caseListPageNumber,
          "pagesize": fetchDataSize
        },
        withAuth: false);

    isLoading = false;
    isLoadMore = false;

    response.fold((l) {
      AppLog.print('left----> ' + l.toString());
      showErrorToast(l.toString());
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
        showSuccessToast(isLoadMore ? 'you are done' : 'No Recipes');
      }
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
          'caseid': caseModel.caseId
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

  clearData() {
    listCases.clear();
    caseListPageNumber = 1;
  }
}
