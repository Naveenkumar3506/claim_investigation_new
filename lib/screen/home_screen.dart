import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/models/report_model.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/providers/multipart_upload_provider.dart';
import 'package:claim_investigation/screen/case_list_screen.dart';
import 'package:claim_investigation/storage/db_helper.dart';
import 'package:claim_investigation/storage/db_manager.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/app_toast.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:connectivity/connectivity.dart';
import 'package:file/local.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:version/version.dart';

class HomeScreen extends BasePage {
  static const routeName = '/homeScreen';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseState<HomeScreen> {
  Position oldPosition;
  String folderPath = '';
  DateTime currentBackPressTime;

  @override
  void initState() {
    super.initState();
    pref.caseTypeSelected = 'All';
    // live tracking
    Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high)
        .listen((Position position) async {
      if (position != null) {
        if (oldPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
              oldPosition.latitude,
              oldPosition.longitude,
              position.latitude,
              position.longitude);
          if (distanceInMeters >= 10.0) {
            oldPosition = position;
          } else {
            return;
          }
        } else {
          oldPosition = position;
        }

        /// Check internet connection
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult != ConnectivityResult.none) {
          Provider.of<ClaimProvider>(context, listen: false)
              .updateLocation(
                  position.latitude.toString(), position.longitude.toString())
              .then((value) {}, onError: (error) {});
        }
      }
      // print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
    });

    Future.delayed(Duration(milliseconds: 50)).then((value) async {
      var appDir = await getApplicationDocumentsDirectory();
      if (Platform.isIOS) {
        appDir = await getApplicationDocumentsDirectory();
      } else {
        appDir = await getExternalStorageDirectory();
      }
      pref.appDocPath = appDir.path;

      _getDashBoard();

      /* final RemoteConfig remoteConfig = await RemoteConfig.instance;
      await remoteConfig.fetch(expiration: const Duration(hours: 0));
      await remoteConfig.activateFetched();
      print('welcome message: ' + remoteConfig.getString('app_status'));
      Map<String, dynamic> appStatus =
          jsonDecode(remoteConfig.getString('app_status'));
      Version localAppVersionNum = Version.parse(appHelper.getVersionNumber());
      if (appStatus != null && appStatus.isNotEmpty) {
        if (Platform.isIOS) {
          Version remoteVersionNum = Version.parse(appStatus["version_no"]);
          bool isForceUpdate = appStatus["is_force_update"];
          if (remoteVersionNum != null && isForceUpdate != null) {
            if (remoteVersionNum > localAppVersionNum && isForceUpdate) {
              print('Update available force');
              showVersionDialogCompulsory(context);
            } else if (remoteVersionNum > localAppVersionNum &&
                !isForceUpdate) {
              print('Update available');
              showVersionDialog(context);
            } else {
              print('App is up to date');
            }
          }
        } else if (Platform.isAndroid) {
          Version remoteVersionNum = Version.parse(appStatus["a_version_no"]);
          bool isForceUpdate = appStatus["a_is_force_update"];
          if (remoteVersionNum != null && isForceUpdate != null) {
            if (remoteVersionNum > localAppVersionNum && isForceUpdate) {
              print('Update available force');
              showVersionDialogCompulsory(context);
            } else if (remoteVersionNum > localAppVersionNum &&
                !isForceUpdate) {
              print('Update available');
              showVersionDialog(context);
            } else {
              print('App is up to date');
            }
          }
        }
      } */
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
        pref.caseTypeSelected = title;
        showLoadingDialog();
        await Provider.of<ClaimProvider>(SizeConfig.cxt, listen: false)
            .getNewCaseList(true, title)
            .then((value) async {
          await Provider.of<ClaimProvider>(context, listen: false)
              .getCaseFromDB()
              .then((value) {
            //hide dialog
            if (value.isEmpty) {
              Navigator.pop(context);
            }

            Navigator.pop(context);
            Get.toNamed(CaseListScreen.routeName);
          });
        }, onError: (error) async {
          await Provider.of<ClaimProvider>(context, listen: false)
              .getCaseFromDB()
              .then((value) {
            //hide dialog
            if (value.isEmpty) {
              // Navigator.pop(context);
            }
            debugPrint(error.toString());
            Navigator.pop(context);
            Get.toNamed(CaseListScreen.routeName);
          });
        });
      },
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      AppToast.toast('Double tap to exit App');
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final double itemHeight = (SizeConfig.screenWidth) / 3 + 20;
    final double itemWidth = SizeConfig.screenWidth / 3;

    return Scaffold(
        appBar: AppBar(
          title: Text('Pre Claim'),
          actions: [
            InkWell(
              onTap: () {
                getCasesToSync();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.sync),
              ),
            )
          ],
        ),
        body: WillPopScope(
          onWillPop: onWillPop,
          child: Consumer<ClaimProvider>(builder: (_, claimProvider, child) {
            if (claimProvider.reportModel == null) {
              return Center(
                child: Platform.isAndroid
                    ? const CircularProgressIndicator()
                    : const CupertinoActivityIndicator(radius: 15),
              );
            }
            return RefreshIndicator(
              onRefresh: _getDashBoard,
              child: ModalProgressHUD(
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
                            return itemView('New',
                                claimProvider.reportModel.reportModelNew);
                          } else if (index == 2) {
                            return itemView('Claim Document Pickup',
                                claimProvider.reportModel.claimDocumentPickup);
                          } else if (index == 3) {
                            return itemView(
                                'Closed', claimProvider.reportModel.closed);
                          } else if (index == 4) {
                            return itemView(
                                'Actioned by Investigator',
                                claimProvider
                                    .reportModel.actionedByInvestigator);
                          }
                          return itemView('', 0);
                        },
                        itemCount: 5,
                      ),
                    ),
                    RaisedButton(
                      color: primaryColor,
                      onPressed: () async {
                        pref.caseTypeSelected = 'All';
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
              ),
            );
          }),
        ));
  }

  // sync
  Future getCasesToSync() async {
    /// Check internet connection
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      AppToast.toast(
        'No internet connection..',
      );
      return;
    }
    //
    final arrayCases = await DBHelper.getCasesToSync();
    if (arrayCases.isNotEmpty) {
      AppToast.toast(
        'Syncing offline data..',
      );
      for (CaseModel model in arrayCases) {
        await _submitReport(model).then((success) {
          if (!success) {
            return;
          }
        });
      }
    } else {
      AppToast.toast(
        'No data to sync ',
      );
    }
  }

  Future<bool> _submitReport(CaseModel _caseModel) async {
    var appDir = await getApplicationDocumentsDirectory();
    if (Platform.isIOS) {
      appDir = await getApplicationDocumentsDirectory();
    } else {
      appDir = await getExternalStorageDirectory();
    }
    folderPath = '${appDir.path}/${_caseModel.caseId}';

    final results = await Future.wait([
      uploadImage(_caseModel),
      uploadImage2(_caseModel),
      uploadPDF1(_caseModel),
      uploadPDF2(_caseModel),
      uploadPDF3(_caseModel),
      uploadSign(_caseModel),
      uploadDocument(_caseModel),
      uploadAudio(_caseModel),
      uploadVideo(_caseModel)
    ]);

    if (results.where((element) => element == false).length == 0) {
      await Provider.of<ClaimProvider>(context, listen: false)
          .submitReport(_caseModel)
          .then((isSuccess) async {
        if (isSuccess) {
          // showSuccessToast('Cases Details submitted successfully');
          DBHelper.deleteCase(_caseModel, DbManager.syncCaseTable);
          DBHelper.deleteCase(_caseModel, DbManager.caseTable);
          DBHelper.deleteCase(_caseModel, DbManager.PIVCaseTable);
          DBHelper.deleteCase(_caseModel, DbManager.NewCaseTable);
          DBHelper.deleteCase(_caseModel, DbManager.CDPCaseTable);
          DBHelper.deleteCase(_caseModel, DbManager.ClosedCaseTable);
          DBHelper.deleteCase(_caseModel, DbManager.InvestigatorCaseTable);
          final dir = Directory(folderPath);
          dir.deleteSync(recursive: true);
          return true;
        } else {
          return false;
        }
      }, onError: (error) {
        return false;
      });
    } else {
      AppToast.toast(
        'Sync failed ',
      );
      return false;
    }
  }

//
  Future<bool> uploadImage(CaseModel _caseModel) async {
    bool _validImageURL = Uri.parse(_caseModel.image).isAbsolute;
    if (!_validImageURL && _caseModel.image.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.image}"),
              MimeMediaType.image, _caseModel, 'image');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadImage2(CaseModel _caseModel) async {
    bool _validImageURL = Uri.parse(_caseModel.image2).isAbsolute;
    if (!_validImageURL && _caseModel.image2.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.image2}"),
              MimeMediaType.image, _caseModel, 'image2');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadVideo(CaseModel _caseModel) async {
    bool _validVideoURL = Uri.parse(_caseModel.videoFilePath).isAbsolute;
    if (!_validVideoURL && _caseModel.videoFilePath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.videoFilePath}"),
              MimeMediaType.video, _caseModel, 'video');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadAudio(CaseModel _caseModel) async {
    bool _validAudioURL = Uri.parse(_caseModel.audioFilePath).isAbsolute;
    if (!_validAudioURL && _caseModel.audioFilePath.isNotEmpty) {
      final LocalFileSystem localFileSystem = LocalFileSystem();
      File _audioFile =
          localFileSystem.file("$folderPath/${_caseModel.audioFilePath}");
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_audioFile, MimeMediaType.audio, _caseModel, 'audio');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF1(CaseModel _caseModel) async {
    bool _validPDF1URL = Uri.parse(_caseModel.pdf1FilePath).isAbsolute;
    if (!_validPDF1URL && _caseModel.pdf1FilePath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.pdf1FilePath}"),
              MimeMediaType.pdf, _caseModel, 'pdf1');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF2(CaseModel _caseModel) async {
    bool _validPDF2URL = Uri.parse(_caseModel.pdf2FilePath).isAbsolute;
    if (!_validPDF2URL && _caseModel.pdf2FilePath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.pdf2FilePath}"),
              MimeMediaType.pdf, _caseModel, 'pdf2');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF3(CaseModel _caseModel) async {
    bool _validPDF3URL = Uri.parse(_caseModel.pdf3FilePath).isAbsolute;
    if (!_validPDF3URL && _caseModel.pdf3FilePath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.pdf3FilePath}"),
              MimeMediaType.pdf, _caseModel, 'pdf3');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadDocument(CaseModel _caseModel) async {
    bool _validExcelURL = Uri.parse(_caseModel.excelFilepath).isAbsolute;
    if (!_validExcelURL && _caseModel.excelFilepath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.excelFilepath}"),
              MimeMediaType.excel, _caseModel, 'excel');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadSign(CaseModel _caseModel) async {
    bool _validSignURL = Uri.parse(_caseModel.signatureFilePath).isAbsolute;
    if (!_validSignURL && _caseModel.signatureFilePath.isNotEmpty) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(File("$folderPath/${_caseModel.signatureFilePath}"),
              MimeMediaType.image, _caseModel, 'signature');
    } else {
      return Future.value(true);
    }
  }

  Future _getDashBoard() async {
    await Provider.of<ClaimProvider>(context, listen: false)
        .getDashBoard()
        .then((value) async {
      await Provider.of<ClaimProvider>(context, listen: false)
          .getDashBoardFromDB();
    }, onError: (error) async {
      await Provider.of<ClaimProvider>(context, listen: false)
          .getDashBoardFromDB();
    });
  }
}
