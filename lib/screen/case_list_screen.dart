import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/screen/case_details_screen.dart';
import 'package:claim_investigation/util/app_log.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:claim_investigation/widgets/empty_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class CaseListScreen extends BasePage {
  static const routeName = '/caseListScreen';

  @override
  _CaseListState createState() => _CaseListState();
}

class _CaseListState extends BaseState<CaseListScreen> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    scrollListener();
    Future.delayed(Duration(milliseconds: 700), () async {
     // Provider.of<ClaimProvider>(SizeConfig.cxt, listen: false).getCaseList(true);
    });
    super.initState();
  }

  scrollListener() {
    final provider = Provider.of<ClaimProvider>(context, listen: false);
    provider.scrollController = _scrollController;
    _scrollController.addListener(() {
      if (pref.caseTypeSelected == 'All') {
        if ((_scrollController.position.maxScrollExtent ==
            _scrollController.offset) &&
            (provider.listCases.length % provider.fetchDataSize) == 0) {
          provider.getCaseList(false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case List'),
      ),
      body: Consumer<ClaimProvider>(
        builder: (_, claimProvider, child) {
          AppLog.print('loaded');
          return ModalProgressHUD(
            inAsyncCall: claimProvider.isLoading,
            child: claimProvider.listCases.isEmpty
                ? EmptyMessage('No Case Found.')
                : ListView.builder(
                    controller: claimProvider.scrollController,
                    itemCount: claimProvider.listCases.length + 1,
                    itemBuilder: (_, index) {
                      if (index == claimProvider.listCases.length) {
                        return Container(
                          height: 50.0,
                          color: Colors.transparent,
                          child: Center(
                            child: claimProvider.isLoadMore
                                ? new CircularProgressIndicator()
                                : null,
                          ),
                        );
                      }

                      final _case = claimProvider.listCases[index];
                      final formatCurrency =
                          new NumberFormat.simpleCurrency(locale: 'en_IN');

                      return InkWell(
                        onTap: () {
                          Get.toNamed(CaseDetailsScreen.routeName,
                              arguments: _case);
                        },
                        child: Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  'Policy No. : ',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                ),
                                Text(
                                  '${_case.policyNumber}',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text('SumAssured : ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                    Text(
                                        '${formatCurrency.format(_case.sumAssured)}',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14)),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text('IntimationType : ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                    Text('${_case.intimationType ?? ""}',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14)),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text('InvestigationType : ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                    Text(
                                        _case.investigation != null ? '${_case.investigation.investigationType}' : "",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14)),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text('Status : ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                    Text('${_case.caseStatus}',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
