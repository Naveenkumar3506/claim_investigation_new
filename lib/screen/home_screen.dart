import 'dart:async';
import 'dart:io';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/screen/case_list_screen.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class HomeScreen extends BasePage {
  static const routeName = '/homeScreen';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high)
            .listen((Position position) {
      if (position != null) {
        //  Provider.of<ClaimProvider>(context, listen: false).updateLocation(position.latitude.toString(), position.longitude.toString());
      }
      //  print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
    });

    Future.delayed(Duration(milliseconds: 50)).then((value) async {
      await Provider.of<ClaimProvider>(context, listen: false)
          .getDashBoardFromDB();
      await Provider.of<ClaimProvider>(context, listen: false).getDashBoard().then((value) async {
      });
    });
  }

  itemView(String title, int count) {
    return InkWell(
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Container(
            height: (SizeConfig.screenWidth / 3) - 45,
            width: (SizeConfig.screenWidth / 3) - 45,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  70,
                ),
              ),
              border: Border.all(
                width: 3,
                color: Colors.grey[300],
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            child: Center(
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      onTap: () async {
        showLoadingDialog();
        await Provider.of<ClaimProvider>(SizeConfig.cxt, listen: false)
            .getNewCaseList(true, title)
            .then((value) {
          //hide dialog
          if (value.isEmpty) {
            Navigator.pop(context);
          }
          Navigator.pop(context);
          Get.toNamed(CaseListScreen.routeName);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final double itemHeight = (SizeConfig.screenWidth) / 3 + 20;
    final double itemWidth = SizeConfig.screenWidth / 3;

    return Scaffold(
        appBar: AppBar(
          title: Text('Pre Claim'),
        ),
        body:  Consumer<ClaimProvider>(builder: (_, claimProvider, child) {
          if (claimProvider.reportModel == null) {
            return Center(
              child: Platform.isAndroid
                  ? const CircularProgressIndicator()
                  : const CupertinoActivityIndicator(radius: 15),
            );
          }
          return ModalProgressHUD(
            inAsyncCall: claimProvider.isLoading,
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: (itemWidth / itemHeight),
                    ),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return itemView('PIV/PRV/LIVE count',
                            claimProvider.reportModel.pivPrvLiveCount);
                      } else if (index == 1) {
                        return itemView(
                            'New', claimProvider.reportModel.reportModelNew);
                      } else if (index == 2) {
                        return itemView('Claim Document Pickup',
                            claimProvider.reportModel.claimDocumentPickup);
                      } else if (index == 3) {
                        return itemView(
                            'Closed', claimProvider.reportModel.closed);
                      } else if (index == 4) {
                        return itemView('Actioned by Investigator',
                            claimProvider.reportModel.actionedByInvestigator);
                      }
                      return itemView('', 0);
                    },
                    itemCount: 5,
                  ),
                ),
                RaisedButton(
                  color: primaryColor,
                  onPressed: () async {
                    showLoadingDialog();
                    await Provider.of<ClaimProvider>(SizeConfig.cxt,
                            listen: false)
                        .getCaseList(true)
                        .then((value) async {
                      await Provider.of<ClaimProvider>(SizeConfig.cxt,
                              listen: false)
                          .getCasesFromDB();
                      //hide dialog
                      Navigator.pop(context);
                      Get.toNamed(CaseListScreen.routeName);
                    }, onError: (error) async {
                      await Provider.of<ClaimProvider>(SizeConfig.cxt,
                          listen: false)
                          .getCasesFromDB();
                      //hide dialog
                      Navigator.pop(context);
                      Get.toNamed(CaseListScreen.routeName);
                    });
                  },
                  child: Text(
                    'View All Cases',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 5,
                )
              ],
            ),
          );
        }));
  }
}
