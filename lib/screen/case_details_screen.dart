import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/providers/multipart_upload_provider.dart';
import 'package:claim_investigation/screen/forms_piv.dart';
import 'package:claim_investigation/screen/full_image_screen.dart';
import 'package:claim_investigation/screen/pdfView_screen.dart';
import 'package:claim_investigation/storage/db_helper.dart';
import 'package:claim_investigation/storage/db_manager.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/app_toast.dart';
import 'package:claim_investigation/util/size_constants.dart';
import 'package:claim_investigation/widgets/adaptive_widgets.dart';
import 'package:claim_investigation/widgets/video_player_screen.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:claim_investigation/util/color_contants.dart';
import 'package:image/image.dart' as ui;
import 'package:path/path.dart' as path;

class CaseDetailsScreen extends BasePage {
  static const routeName = '/caseDetailScreen';

  @override
  _CaseDetailsScreenState createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends BaseState<CaseDetailsScreen> {
  CaseModel _caseModel;
  final formatCurrency = new NumberFormat.simpleCurrency(locale: 'en_IN');
  final dateFormatter = DateFormat('dd/MM/yyyy');
  final _descFocusNode = FocusNode();
  Timer timer;
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  final LocalFileSystem localFileSystem = LocalFileSystem();
  AudioPlayer audioPlayer;
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  AudioPlayerState audioPlayerState;
  bool isNotEditable = false;
  bool isPIVFormFilled = false;
  TextEditingController descTextController = TextEditingController();
  TextEditingController remarksTextController = TextEditingController();
  TextEditingController documentTextController = TextEditingController();
  String folderPath = '';
  List<CaseDoc> listImageDoc = [];
  List<CaseDoc> listVideoDoc = [];
  List<CaseDoc> listPDFDoc = [];
  int maxImageCount = 5;
  final _imageListController = ScrollController();
  final _videoListController = ScrollController();
  final _pdfListController = ScrollController();
  io.File _signFile, _audioFile, _documentFile;
  String _documentFileName;

  void initState() {
    Provider.of<ClaimProvider>(context, listen: false).pivAnswers = null;
    _caseModel = Get.arguments;
    if (_caseModel.forms != null && _caseModel.forms != "") {
      Provider.of<ClaimProvider>(context, listen: false).pivAnswers =
          jsonDecode(_caseModel.forms);
    }

    descTextController.text = _caseModel.caseDescription;
    remarksTextController.text = _caseModel.newRemarks;
    super.initState();
    //
    if (_caseModel.caseStatus.toLowerCase() == "closed".toLowerCase() ||
        pref.caseTypeSelected == "Actioned by Investigator") {
      isNotEditable = true;
    }
    //
    if (_caseModel.newRemarks != null && _caseModel.newRemarks.isNotEmpty) {
      remarksTextController.text = _caseModel.newRemarks;
    }

    new Future.delayed(Duration(milliseconds: 50), () async {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
      var appDir = await getApplicationDocumentsDirectory();
      if (io.Platform.isIOS) {
        appDir = await getApplicationDocumentsDirectory();
      } else {
        appDir = await getExternalStorageDirectory();
      }
      folderPath = await _createFolder('${appDir.path}/${_caseModel.caseId}');
      await _getSavedFiles();
    });
  }

  _getSavedFiles() {
    //
    listImageDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.IMAGE)
            .toList()
        : [];
    for (var imageDoc in listImageDoc) {
      if (!imageDoc.isURL && !imageDoc.docName.contains("/")) {
        imageDoc.docName = folderPath + "/" + imageDoc.docName;
      }
    }

    //
    listVideoDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.VIDEO)
            .toList()
        : [];
    for (var videoDoc in listVideoDoc) {
      if (!videoDoc.isURL && !videoDoc.docName.contains("/")) {
        videoDoc.docName = folderPath + "/" + videoDoc.docName;
      }
    }

    listPDFDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.PDF)
            .toList()
        : [];
    for (var pdfDoc in listPDFDoc) {
      if (!pdfDoc.isURL && !pdfDoc.docName.contains("/")) {
        pdfDoc.docName = folderPath + "/" + pdfDoc.docName;
      }
    }
    //
    final audioDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) =>
                element.docType == DocType.AUDIO && element.isURL == false)
            .toList()
        : [];
    if (audioDoc.isNotEmpty) {
      if (!audioDoc.first.isURL && !audioDoc.first.docName.contains("/")) {
        _audioFile =
            localFileSystem.file("$folderPath/${audioDoc.first.docName}");
      }
    }

    final excelDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.EXCEL)
            .toList()
        : [];
    if (excelDoc.isNotEmpty) {
      if (!excelDoc.first.isURL && !excelDoc.first.docName.contains("/")) {
        _documentFile = io.File(folderPath + "/${excelDoc.first.docName}");
        documentTextController.text = 'Excel';
      }
    }
    setState(() {});
  }

  Future _initAudioRecording() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/audio_recorder_';
//         if (io.Platform.isIOS) {
//           appDocDirectory = await getApplicationDocumentsDirectory();
//         } else {
//           appDocDirectory = await getExternalStorageDirectory();
//         }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = folderPath +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _startAudioRecording() async {
    if (isNotEditable) {
      return;
    }
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });
      print(_currentStatus);

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resumeAudioRecording() async {
    if (isNotEditable) {
      return;
    }
    await _recorder.resume();
    var current = await _recorder.current(channel: 0);
    setState(() {
      _current = current;
      _currentStatus = _current.status;
    });
  }

  _pauseAudioRecording() async {
    if (isNotEditable) {
      return;
    }
    await _recorder.pause();
    var current = await _recorder.current(channel: 0);
    setState(() {
      _current = current;
      _currentStatus = _current.status;
    });
  }

  _stopAudioRecording() async {
    if (isNotEditable) {
      return;
    }
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    _audioFile = localFileSystem.file(result.path);
    setState(() {
      _current = result;
      _currentStatus = _current.status;
    });
  }

  void onPlayAudio() async {
    audioPlayer = AudioPlayer();
    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
      setState(() {
        audioPlayerState = state;
      });
    });
    if (_audioFile != null) {
      await audioPlayer.play(_audioFile.path, isLocal: true);
    } else {
      final audioDocs = _caseModel.caseDocs != null
          ? _caseModel.caseDocs
              .where((element) =>
                  element.docType == DocType.AUDIO && element.isURL)
              .toList()
          : [];
      if (audioDocs.isNotEmpty) {
        await audioPlayer.play(Uri.encodeFull(audioDocs.first.docName));
      }
    }

    // else if (_current != null) {
    // await audioPlayer.play(_current.path, isLocal: true);
    // }
  }

  void onStopAudio() async {
    if (audioPlayer != null) {
      audioPlayer.stop();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      /* showAdaptiveAlertDialog(
        context: context,
        title: "Alert",
        content: "Location is mandatory.",
        defaultActionText: "Settings",
        cancelActionText: "Cancel",
        defaultAction: () {
          Geolocator.openAppSettings();
        },
      ); */
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied. Go to settings and enable the location for the app');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future _onSubmitReport() async {
    if (isNotEditable) {
      return;
    }
    hideKeyboard();
    showLoadingDialog();
    await _determinePosition().then((position) async {
      if (position != null) {
        _caseModel.caseDescription = descTextController.text;
        _caseModel.latitude = position.latitude.toStringAsFixed(5);
        _caseModel.longitude = position.longitude.toStringAsFixed(5);
        _caseModel.newRemarks = remarksTextController.text;

        final listNewImages =
            listImageDoc.where((element) => element.isURL == false).toList();

        List<CaseDoc> listWaterMarkImages = [];
        for (var imageDoc in listNewImages) {
          ui.Image originalImage =
              ui.decodeImage(io.File(imageDoc.docName).readAsBytesSync());
          ui.drawString(
            originalImage,
            ui.arial_48,
            originalImage.width - 500,
            originalImage.height - 100,
            '${_caseModel.latitude}, ${_caseModel.longitude}',
          );
          // Store the watermarked image to a File
          List<int> wmImage = ui.encodePng(originalImage);
          await _createWaterMarkFileFromString(wmImage).then((value) {
            imageDoc.docName = value.path;
            listWaterMarkImages.add(imageDoc);
          });
        }

        //---- Adding Questionnaire
        Provider.of<ClaimProvider>(context, listen: false)
            .addPIVQuestionnaire(_caseModel.caseId)
            .then((value) {});

        var uploadCount = 0;
        var resultCount = 0;
        for (var imageDoc in listWaterMarkImages) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(io.File(imageDoc.docName), MimeMediaType.image,
                  _caseModel, 'image')
              .then((isImageSuccess) async {
            if (isImageSuccess) {
              resultCount++;
            }
          });
        }
        //
        if (_audioFile != null) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(_audioFile, MimeMediaType.audio, _caseModel, 'audio')
              .then((isAudioSuccess) async {
            if (isAudioSuccess) {
              resultCount++;
            }
          });
        }
        //
        final listNewPDFs =
            listPDFDoc.where((element) => element.isURL == false).toList();
        for (var pdfDoc in listNewPDFs) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(
                  io.File(pdfDoc.docName), MimeMediaType.pdf, _caseModel, 'pdf')
              .then((isImageSuccess) async {
            if (isImageSuccess) {
              resultCount++;
            }
          });
        }
        //
        if (_documentFile != null) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(
                  _documentFile, MimeMediaType.excel, _caseModel, 'excel')
              .then((isDocSuccess) {
            if (isDocSuccess) {
              resultCount++;
            }
          });
        }
        if (_signFile != null) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(
                  _signFile, MimeMediaType.excel, _caseModel, 'signature')
              .then((isSignSuccess) {
            if (isSignSuccess) {
              resultCount++;
            }
          });
        }
        //
        final listNewVideos =
            listVideoDoc.where((element) => element.isURL == false).toList();
        for (var videoDoc in listNewVideos) {
          uploadCount++;
          await Provider.of<MultiPartUploadProvider>(context, listen: false)
              .uploadFile(io.File(videoDoc.docName), MimeMediaType.video,
                  _caseModel, 'video')
              .then((isImageSuccess) async {
            if (isImageSuccess) {
              resultCount++;
            }
          });
        }

        if (resultCount == uploadCount) {
          await Provider.of<ClaimProvider>(context, listen: false)
              .submitReport(_caseModel)
              .then((isSuccess) async {
            Navigator.pop(context);
            DBHelper.deleteCase(_caseModel, DbManager.caseTable);
            DBHelper.deleteCase(_caseModel, DbManager.PIVCaseTable);
            DBHelper.deleteCase(_caseModel, DbManager.NewCaseTable);
            DBHelper.deleteCase(_caseModel, DbManager.CDPCaseTable);
            DBHelper.deleteCase(_caseModel, DbManager.ClosedCaseTable);
            DBHelper.deleteCase(_caseModel, DbManager.InvestigatorCaseTable);
            //
            await Provider.of<ClaimProvider>(context, listen: false)
                .getCaseFromDB()
                .then((value) {});
            //
            Provider.of<ClaimProvider>(context, listen: false).notifyModel();
            Get.back();
            showSuccessToast('Cases Details submitted successfully');
          });
        } else {
          Navigator.pop(context);
          showErrorToast(
              'Oops, uploading attachments failed. Please try again');
        }
      } else {
        Navigator.pop(context);
        showErrorToast('Oops, unable to get your location. Please try again');
      }
    }, onError: (error) {
      Navigator.pop(context);
      showErrorToast(error.toString());
    });
  }

  Future saveDraft() async {
    showLoadingDialog(hint: 'Saving data...');
    await _determinePosition().then((position) async {
      if (position != null) {
        _caseModel.caseDescription = descTextController.text;
        _caseModel.latitude = position.latitude.toStringAsFixed(5);
        _caseModel.longitude = position.longitude.toStringAsFixed(5);
        _caseModel.newRemarks = remarksTextController.text;

        // Saving image to app folder
        final listNewImages =
            listImageDoc.where((element) => element.isURL == false).toList();
        List<CaseDoc> listWaterMarkImages = [];
        for (var imageDoc in listNewImages) {
          ui.Image originalImage =
              ui.decodeImage(io.File(imageDoc.docName).readAsBytesSync());
          ui.drawString(
            originalImage,
            ui.arial_48,
            originalImage.width - 500,
            originalImage.height - 100,
            '${_caseModel.latitude}, ${_caseModel.longitude}',
          );
          // Store the watermarked image to a File
          List<int> wmImage = ui.encodePng(originalImage);
          await _createWaterMarkFileFromString(wmImage).then((value) {
            String fileName = path.basename(value.path);
            imageDoc.docName = fileName;
            listWaterMarkImages.add(imageDoc);
          });
        }
        // Saving pdf to app folder
        final listNewPDFs =
            listPDFDoc.where((element) => element.isURL == false).toList();
        for (var pdfDoc in listNewPDFs) {
          io.File savedFile =
              await _saveFileToAppDirectory(io.File(pdfDoc.docName), pdfDoc);
          String fileName = path.basename(savedFile.path);
          pdfDoc.docName = fileName;
        }
        // Saving videos to app folder
        final listNewVideos =
            listVideoDoc.where((element) => element.isURL == false).toList();
        for (var videoDoc in listNewVideos) {
          io.File savedFile = await _saveFileToAppDirectory(
              io.File(videoDoc.docName), videoDoc);
          String fileName = path.basename(savedFile.path);
          videoDoc.docName = fileName;
        }

        List<CaseDoc> listValidImages = _caseModel.caseDocs != null
            ? _caseModel.caseDocs
                .where((element) =>
                    element.docType == DocType.IMAGE && element.isURL)
                .toList()
            : [];
        List<CaseDoc> listValidVideos = _caseModel.caseDocs != null
            ? _caseModel.caseDocs
                .where((element) =>
                    element.docType == DocType.VIDEO && element.isURL)
                .toList()
            : [];
        List<CaseDoc> listValidPDFs = _caseModel.caseDocs != null
            ? _caseModel.caseDocs
                .where((element) =>
                    element.docType == DocType.PDF && element.isURL)
                .toList()
            : [];
        //

        List<CaseDoc> newCaseDoc = [];
        newCaseDoc.addAll(listValidImages);
        newCaseDoc.addAll(listWaterMarkImages);
        //
        newCaseDoc.addAll(listValidVideos);
        newCaseDoc.addAll(listNewVideos);
        //
        newCaseDoc.addAll(listValidPDFs);
        newCaseDoc.addAll(listNewPDFs);
        // Saving audio to app folder
        if (_audioFile != null) {
          var newAudio = CaseDoc();
          newAudio.isURL = false;
          newAudio.docType = DocType.AUDIO;
          // newAudio.docName = _audioFile.path;
          io.File savedFile =
              await _saveFileToAppDirectory(_audioFile, newAudio);
          String fileName = path.basename(savedFile.path);
          newAudio.docName = fileName;
          newCaseDoc.add(newAudio);
        }
        // Saving sign to app folder
        if (_signFile != null) {
          var newSign = CaseDoc();
          newSign.isURL = false;
          newSign.docType = DocType.SIGNATURE;
          // newSign.docName = _signFile.path;
          io.File savedFile = await _saveFileToAppDirectory(_signFile, newSign);
          String fileName = path.basename(savedFile.path);
          newSign.docName = fileName;
          newCaseDoc.add(newSign);
        }
        // Saving excel to app folder
        if (_documentFile != null) {
          var newExcel = CaseDoc();
          newExcel.isURL = false;
          newExcel.docType = DocType.EXCEL;
          // newExcel.docName = _documentFile.path;
          io.File savedFile =
              await _saveFileToAppDirectory(_documentFile, newExcel);
          String fileName = path.basename(savedFile.path);
          newExcel.docName = fileName;
          newCaseDoc.add(newExcel);
        }
        //
        if (newCaseDoc.isNotEmpty) {
          _caseModel.caseDocs = newCaseDoc;
        }
        // Save PIV form
        final claimProvider =
            Provider.of<ClaimProvider>(context, listen: false);
        if (claimProvider.pivAnswers != null &&
            claimProvider.pivAnswers != {}) {
          _caseModel.forms = jsonEncode(claimProvider.pivAnswers);
        }
        //
        await DBHelper.saveCase(_caseModel, DbManager.syncCaseTable);
        print(pref.caseTypeSelected);
        //
        if (pref.caseTypeSelected != null && pref.caseTypeSelected == 'All') {
          await DBHelper.updateCaseDetail(_caseModel, DbManager.caseTable);
          await DBHelper.updateCaseDetail(_caseModel, DbManager.PIVCaseTable);
          await DBHelper.updateCaseDetail(_caseModel, DbManager.NewCaseTable);
          await DBHelper.updateCaseDetail(_caseModel, DbManager.CDPCaseTable);
        } else if (pref.caseTypeSelected != null &&
            pref.caseTypeSelected == 'PIV/PRV/LIVE count') {
          await DBHelper.updateCaseDetail(_caseModel, DbManager.PIVCaseTable);
        } else if (pref.caseTypeSelected != null &&
            pref.caseTypeSelected == "New") {
          await DBHelper.updateCaseDetail(_caseModel, DbManager.NewCaseTable);
        } else if (pref.caseTypeSelected != null &&
            pref.caseTypeSelected == "Claim Document Pickup") {
          await DBHelper.updateCaseDetail(_caseModel, DbManager.CDPCaseTable);
        } else if (pref.caseTypeSelected != null &&
            pref.caseTypeSelected == "Closed") {
          await DBHelper.updateCaseDetail(
              _caseModel, DbManager.ClosedCaseTable);
        } else if (pref.caseTypeSelected != null &&
            pref.caseTypeSelected == "Actioned by Investigator") {
          await DBHelper.updateCaseDetail(
              _caseModel, DbManager.InvestigatorCaseTable);
        }
        await DBHelper.updateCaseDetail(_caseModel, DbManager.caseTable);
        Navigator.pop(context);
        Get.back();
        AppToast.toast("Saved as Draft");
      }
    }, onError: (error) {
      Navigator.pop(context);
      showErrorToast(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Case Detail'),
        ),
        body: GestureDetector(
          onTap: () {
            hideKeyboard();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(children: [
                Card(
                    child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Policy No. : ',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text(
                            '${_caseModel.policyNumber}',
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SumAssured : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                              '${formatCurrency.format(_caseModel.sumAssured)}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nature of Investigation : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                              _caseModel.investigationNature != null
                                  ? '${_caseModel.investigationNature.natureOfInvestigationType ?? ""}'
                                  : "",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('InvestigationType : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                              _caseModel.investigationType != null
                                  ? '${_caseModel.investigationType}'
                                  : "",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text(
                            'City : ',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text(
                            '${_caseModel.location.city}',
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${_caseModel.caseStatus}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                )),
                Card(
                  child: ListTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insured Name : ',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        Text(
                          '${_caseModel.insuredName}',
                          style: TextStyle(color: Colors.black, fontSize: 15),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Insured Gender : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text(
                                _caseModel.gender == null
                                    ? "-"
                                    : _caseModel.gender,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Insured DOB : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text(
                                _caseModel.insuredDob == null
                                    ? "-"
                                    : '${dateFormatter.format(_caseModel.insuredDob)}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _caseModel.investigationType == "CDP"
                                    ? 'Insured DOD: '
                                    : 'Insured Diagnosis Date: ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text(
                                _caseModel.investigationType == "CDP"
                                    ? _caseModel.insuredDod == null
                                        ? "-"
                                        : '${dateFormatter.format(_caseModel.insuredDod)}'
                                    : _caseModel.insuredDiagnosisDate == null
                                        ? "-"
                                        : '${dateFormatter.format(_caseModel.insuredDiagnosisDate)}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Insured Mobile : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text(
                                _caseModel.insuredMob == null
                                    ? "-"
                                    : _caseModel.insuredMob,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Insured Address : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Flexible(
                              child: Text('${_caseModel.insuredAddress.trim()}',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 14),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nominee Name : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                            Text(
                              '${_caseModel.nomineeName}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text('Nominee Contact No. : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text('${_caseModel.nomineeContactNumber}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nominee Address : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Flexible(
                              child: Text(
                                  '${_caseModel.nomineeAddress.trimRight()}',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 14),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text('State : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text('${_caseModel.location.state}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text('Zone : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text('${_caseModel.location.zone.trim()}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description : ',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        _buildTextField(
                            "Enter description here...", descTextController),
                      ],
                    ),
                  ),
                ),
                _buildImageAndVideo(),
                _buildAudioBody(),
                _buildPDFBody(),
                _buildClaimFormatBody(),
                _caseModel.remarks != null && _caseModel.remarks.isNotEmpty
                    ? Card(
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supervisor Remarks : ',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(_caseModel.remarks,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15)),
                            ],
                          ),
                        ),
                      )
                    : Container(),
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remarks : ',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        _buildTextField(
                            "Enter remarks here...", remarksTextController),
                      ],
                    ),
                  ),
                ),
                _buildSignatureBody(),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: CupertinoButton(
                      color: isNotEditable
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      child: Text(
                        'Submit Report',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        _onSubmitReport();
                      },
                    ),
                  ),
                ),
                !isNotEditable
                    ? Padding(
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 15.0, bottom: 20.0),
                        child: SizedBox(
                          width: double.maxFinite,
                          child: CupertinoButton(
                            color: Colors.grey,
                            child: Text(
                              'Save as Draft',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              saveDraft();
                            },
                          ),
                        ),
                      )
                    : Container(),
              ]),
            ),
          ),
        ));
  }

  Widget _buildImageAndVideo() {
    return Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'UPLOAD IMAGE',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: _imageListController,
                shrinkWrap: true,
                itemCount: listImageDoc.length >= maxImageCount
                    ? maxImageCount
                    : listImageDoc.length + 1,
                itemBuilder: (ctx, index) {
                  if (index < listImageDoc.length) {
                    final doc = listImageDoc[index];
                    return InkWell(
                      child: Stack(
                        children: [
                          Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Container(
                              padding: EdgeInsets.all(0.0),
                              width: 160,
                              height: 160,
                              child: doc.isURL
                                  ? CachedNetworkImage(
                                      imageUrl: doc.docName,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          new Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    )
                                  : Image.file(
                                      io.File(doc.docName),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: !doc.isURL
                                ? InkWell(
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        listImageDoc.remove(doc);
                                      });
                                    },
                                  )
                                : Container(),
                          )
                        ],
                      ),
                      onTap: () {
                        if (doc.isURL) {
                          Get.toNamed(FullImageViewScreen.routeName,
                              arguments: {
                                'IMAGE': doc.docName,
                              });
                        }
                      },
                    );
                  } else {
                    // Add image
                    return InkWell(
                      child: Card(
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          width: 160,
                          height: 160,
                          child: Stack(alignment: Alignment.center, children: [
                            // Container(
                            //   decoration: BoxDecoration(
                            //       border: Border.all(color: Colors.grey)),
                            // ),
                            Positioned(
                              top: 20,
                              child: SizedBox(
                                height: 80,
                                width: 80,
                                child: Image.asset(
                                  'assets/images/ic_image_upload_placeholder.png',
                                ),
                              ),
                            ),
                            Positioned(top: 110, child: Text("Add Image"))
                          ]),
                        ),
                      ),
                      onTap: () {
                        if (isNotEditable) {
                          return;
                        }
                        hideKeyboard();
                        imagePickerDialog(() async {
                          //camera
                          await getImageFile(ImageSource.camera)
                              .then((value) async {
                            if (value != null) {
                              setState(() {
                                var newImage = CaseDoc();
                                newImage.isURL = false;
                                newImage.docName = value.path;
                                newImage.docType = DocType.IMAGE;
                                listImageDoc.add(newImage);
                              });
                              _imageListController.animateTo(
                                _imageListController.position.maxScrollExtent,
                                duration: Duration(seconds: 1),
                                curve: Curves.fastOutSlowIn,
                              );
                            }
                          });
                        }, () async {
                          //gallery
                          await getImageFile(ImageSource.gallery).then((value) {
                            if (value != null) {
                              setState(() {});
                            }
                          });
                        });
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'UPLOAD VIDEO (MAX 5 MIN)',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: _videoListController,
                shrinkWrap: true,
                itemCount: listVideoDoc.length >= maxImageCount
                    ? maxImageCount
                    : listVideoDoc.length + 1,
                itemBuilder: (ctx, index) {
                  if (index < listVideoDoc.length) {
                    final doc = listVideoDoc[index];
                    return InkWell(
                      child: Stack(
                        children: [
                          Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Container(
                              padding: EdgeInsets.all(0.0),
                              width: 160,
                              height: 160,
                              child: doc.isURL
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Image(
                                        //     image:
                                        //     FileImage(io.File(videoThumbnailPath))),
                                        InkWell(
                                          child: Icon(
                                            Icons.play_circle_filled_sharp,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 70,
                                          ),
                                          onTap: () {
                                            Get.toNamed(
                                                VideoPlayerScreen.routeName,
                                                arguments: {
                                                  'videoURL': Uri.encodeFull(
                                                      doc.docName)
                                                });
                                          },
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Image.memory(
                                        //   _thumbnail,
                                        //   fit: BoxFit.fill,
                                        // ),
                                        InkWell(
                                          child: Icon(
                                            Icons.play_circle_filled_sharp,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 70,
                                          ),
                                          onTap: () {
                                            Get.toNamed(
                                                VideoPlayerScreen.routeName,
                                                arguments: {
                                                  'file': io.File(doc.docName)
                                                });
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: !doc.isURL
                                ? InkWell(
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        listVideoDoc.remove(doc);
                                      });
                                    },
                                  )
                                : Container(),
                          )
                        ],
                      ),
                      onTap: () {
                        if (doc.isURL) {
                          Get.toNamed(FullImageViewScreen.routeName,
                              arguments: {
                                'IMAGE': doc.docName,
                              });
                        }
                      },
                    );
                  } else {
                    // Add video
                    return InkWell(
                      child: Card(
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          width: 160,
                          height: 160,
                          child: Stack(alignment: Alignment.center, children: [
                            // Container(
                            //   decoration: BoxDecoration(
                            //       border: Border.all(color: Colors.grey)),
                            // ),
                            Positioned(
                              top: 20,
                              child: SizedBox(
                                height: 80,
                                width: 80,
                                child: Image.asset(
                                  'assets/images/ic_video_upload_placeholder.png',
                                ),
                              ),
                            ),
                            Positioned(top: 110, child: Text("Add Video"))
                          ]),
                        ),
                      ),
                      onTap: () {
                        if (isNotEditable) {
                          return;
                        }
                        hideKeyboard();
                        videoPickerDialog(() async {
                          //camera
                          await getVideoFile(ImageSource.camera)
                              .then((file) async {
                            if (file != null) {
                              showLoadingDialog();
                              final thumbnail =
                                  await VideoThumbnail.thumbnailData(
                                video: file.path,
                                imageFormat: ImageFormat.JPEG,
                                maxWidth: 500,
                                quality: 25,
                              );
                              final info =
                                  await VideoCompress.getMediaInfo(file.path);
                              MediaInfo mediaInfo =
                                  await VideoCompress.compressVideo(
                                file.path,
                                quality: VideoQuality.DefaultQuality,
                                deleteOrigin: false, // It's false by default
                              );
                              Navigator.pop(context);
                              print("Original size - ${info.filesize}");
                              print("compress size - ${mediaInfo.filesize}");
                              setState(() {
                                var newVideo = CaseDoc();
                                newVideo.isURL = false;
                                newVideo.docName = mediaInfo.path;
                                newVideo.docType = DocType.VIDEO;
                                newVideo.thumbnail = thumbnail;
                                listVideoDoc.add(newVideo);
                              });
                            }
                          });
                        }, () async {
                          //gallery
                          await getVideoFile(ImageSource.gallery)
                              .then((file) async {
                            if (file != null) {}
                          });
                        });
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ));
  }

  Widget _buildAudioBody() {
    return Card(
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 15,
            ),
            Text(
              'Audio Attachment : ',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
            // new Text("Status : $_currentStatus"),
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: isNotEditable
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceEvenly,
              children: [
                isNotEditable
                    ? SizedBox()
                    : FlatButton(
                        onPressed: () async {
                          onStopAudio();
                          switch (_currentStatus) {
                            case RecordingStatus.Unset:
                              {
                                await _initAudioRecording().then((value) {
                                  _startAudioRecording();
                                });
                                break;
                              }
                            case RecordingStatus.Initialized:
                              {
                                _startAudioRecording();
                                break;
                              }
                            case RecordingStatus.Recording:
                              {
                                _pauseAudioRecording();
                                break;
                              }
                            case RecordingStatus.Paused:
                              {
                                _resumeAudioRecording();
                                break;
                              }
                            case RecordingStatus.Stopped:
                              {
                                _initAudioRecording().then((value) {
                                  _startAudioRecording();
                                });
                                break;
                              }
                            default:
                              break;
                          }
                        },
                        child: _currentStatus == RecordingStatus.Recording
                            ? Column(
                                children: [
                                  Icon(Icons.pause),
                                  Text('Pause'),
                                ],
                              )
                            : Column(
                                children: [
                                  Icon(Icons.record_voice_over),
                                  Text('Record'),
                                ],
                              ),
                        color: primaryColor.withOpacity(0.5),
                      ),
                isNotEditable
                    ? Container()
                    : FlatButton(
                        onPressed: () {
                          if (_currentStatus == RecordingStatus.Recording) {
                            _stopAudioRecording();
                          }
                        },
                        child: Column(
                          children: [
                            Icon(
                              Icons.stop,
                              color: Colors.red,
                            ),
                            Text('Stop')
                          ],
                        ),
                        color: primaryColor.withOpacity(0.5),
                      ),
                audioPlayerState == AudioPlayerState.PLAYING
                    ? FlatButton(
                        onPressed: onStopAudio,
                        child: Column(
                          children: [Icon(Icons.stop), Text('Stop')],
                        ),
                        color: primaryColor.withOpacity(0.5),
                      )
                    : FlatButton(
                        onPressed: onPlayAudio,
                        child: Column(
                          children: [Icon(Icons.play_arrow), Text('Play')],
                        ),
                        color: primaryColor.withOpacity(0.5),
                      ),
              ],
            ),
            SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFBody() {
    return Padding(
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'UPLOAD PDF',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _pdfListController,
              shrinkWrap: true,
              itemCount: listPDFDoc.length >= maxImageCount
                  ? maxImageCount
                  : listPDFDoc.length + 1,
              itemBuilder: (ctx, index) {
                if (index < listPDFDoc.length) {
                  final doc = listPDFDoc[index];
                  return InkWell(
                    child: Card(
                      child: Container(
                        padding: EdgeInsets.all(5.0),
                        width: 160,
                        height: 160,
                        child: Stack(alignment: Alignment.center, children: [
                          Positioned(
                            top: 20,
                            child: SizedBox(
                              height: 80,
                              width: 80,
                              child: Image.asset(
                                'assets/images/ic_pdf_placeholder.png',
                              ),
                            ),
                          ),
                          Positioned(top: 110, child: Text("View PDF")),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: !doc.isURL
                                ? InkWell(
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        listPDFDoc.remove(doc);
                                      });
                                    },
                                  )
                                : Container(),
                          )
                        ]),
                      ),
                    ),
                    onTap: () {
                      if (doc.isURL) {
                        Get.toNamed(PDFViewerCachedFromUrl.routeName,
                            arguments: {"url": doc.docName});
                      } else {
                        Get.toNamed(PDFViewerCachedFromUrl.routeName,
                            arguments: {"path": doc.docName});
                      }
                    },
                  );
                } else {
                  // Add image
                  return InkWell(
                      child: Card(
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          width: 160,
                          height: 160,
                          child: Stack(alignment: Alignment.center, children: [
                            // Container(
                            //   decoration: BoxDecoration(
                            //       border: Border.all(color: Colors.grey)),
                            // ),
                            Positioned(
                              top: 20,
                              child: SizedBox(
                                height: 80,
                                width: 80,
                                child: Image.asset(
                                  'assets/images/ic_pdf_placeholder.png',
                                ),
                              ),
                            ),
                            Positioned(top: 110, child: Text("Add PDF"))
                          ]),
                        ),
                      ),
                      onTap: () async {
                        if (isNotEditable) {
                          return;
                        }
                        hideKeyboard();
                        //
                        FilePickerResult result = await FilePicker.platform
                            .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                                allowCompression: true);
                        if (result != null) {
                          setState(() {
                            PlatformFile platformFile = result.files.first;
                            if (platformFile.extension == "pdf") {
                              final _pdfFile =
                                  io.File(result.files.single.path);
                              var newPDF = CaseDoc();
                              newPDF.isURL = false;
                              newPDF.docName = platformFile.path;
                              newPDF.docType = DocType.PDF;
                              listPDFDoc.add(newPDF);
                            } else {
                              Get.snackbar(
                                  'Alert', 'Please select PDF files only.');
                            }
                          });
                        } else {
                          // User canceled the picker
                        }
                      });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimFormatBody() {
    return Card(
      child: _caseModel.investigationType == 'CDP'
          ? ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _caseModel.investigationType == 'CDP'
                            ? 'Document Pickup Form : '
                            : 'PIV/PIRV/LIVE Form : ',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      _documentFile != null
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  _documentFile = null;
                                  documentTextController.text = null;
                                });
                              },
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                  InkWell(
                    onTap: () async {
                      if (isNotEditable) {
                        return;
                      }
                      if (_caseModel.investigationType == 'CDP') {
                        final ByteData bytes = await rootBundle
                            .load('assets/images/ClaimForm.xlsx');
                        if (io.Platform.isAndroid) {
                          if (!await Permission.storage.isGranted) {
                            showAdaptiveAlertDialog(
                                context: context,
                                title: "Permission denied",
                                content:
                                    "Storage permission is required to save the file to downloads.",
                                defaultActionText: "Ok");
                            return;
                          }
                          String dir = await ExtStorage
                              .getExternalStoragePublicDirectory(
                                  ExtStorage.DIRECTORY_DOWNLOADS);
                          io.File file = new io.File('$dir/ClaimForm.xlsx');
                          await file
                              .writeAsBytes(bytes.buffer.asUint8List())
                              .then((value) {
                            showSuccessToast('Saved to downloads');
                          });
                        } else {
                          await Share.file(
                              'Doc',
                              'ClaimForm.xlsx',
                              bytes.buffer.asUint8List(),
                              'application/vnd.ms-excel',
                              text:
                                  'Claim Form format for document collection');
                        }
                      } else {
                        final ByteData bytes = await rootBundle
                            .load('assets/images/PIVReport.xlsx');
                        if (io.Platform.isAndroid) {
                          if (!await Permission.storage.isGranted) {
                            showAdaptiveAlertDialog(
                                context: context,
                                title: "Permission denied",
                                content:
                                    "Storage permission is required to save the file to downloads.",
                                defaultActionText: "Ok");
                            return;
                          }
                          String dir = await ExtStorage
                              .getExternalStoragePublicDirectory(
                                  ExtStorage.DIRECTORY_DOWNLOADS);
                          io.File file = new io.File('$dir/PIVReport.xlsx');
                          await file
                              .writeAsBytes(bytes.buffer.asUint8List())
                              .then((value) {
                            showSuccessToast('Saved to downloads');
                          });
                        } else {
                          await Share.file(
                              'Doc',
                              'PIVReport.xlsx',
                              bytes.buffer.asUint8List(),
                              'application/vnd.ms-excel',
                              text: 'PIV PIRV Report Format');
                        }
                      }
                    },
                    child: Text(
                      '(Sample Download)',
                      style: TextStyle(color: Colors.blue, fontSize: 15),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: TextField(
                          controller: documentTextController,
                          enabled: false,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headline3,
                          decoration: InputDecoration(
                            hintText: "Select File",
                            filled: false,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (isNotEditable) {
                            if (_caseModel.caseDocs != null &&
                                _caseModel.caseDocs
                                    .where((element) =>
                                        element.docType == DocType.EXCEL)
                                    .toList()
                                    .isNotEmpty) {
                              final excelDoc = _caseModel.caseDocs.firstWhere(
                                  (element) =>
                                      element.docType == DocType.EXCEL);
                              showLoadingDialog(hint: "Downloading...");
                              await Provider.of<ClaimProvider>(context,
                                      listen: false)
                                  .downloadFile(excelDoc.docName,
                                      'excel-${_caseModel.caseId}.xlsx')
                                  .then((value) {
                                Navigator.pop(context);
                                showSuccessToast('File downloaded');
                              });
                            }
                            return;
                          }
                          FilePickerResult result =
                              await FilePicker.platform.pickFiles(
                                  // type: FileType.custom,
                                  // allowedExtensions: ['xlsx, xls, csv'],
                                  allowCompression: true);
                          if (result != null) {
                            setState(() {
                              PlatformFile platformFile = result.files.first;
                              if (platformFile.extension == "xlsx" ||
                                  platformFile.extension == "xls" ||
                                  platformFile.extension == "csv") {
                                _documentFile =
                                    io.File(result.files.single.path);
                                _documentFileName = platformFile.name;
                                documentTextController.text = _documentFileName;
                              } else {
                                Get.snackbar('Alert',
                                    'Please select excel or csv files only.');
                              }
                            });
                          } else {
                            // User canceled the picker
                          }
                        },
                        child: Text(isNotEditable &&
                                _caseModel.caseDocs != null &&
                                _caseModel.caseDocs
                                    .where((element) =>
                                        element.docType == DocType.EXCEL)
                                    .toList()
                                    .isNotEmpty
                            ? 'Download'
                            : 'Select'),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            )
          : ListTile(
              title: Text(
                "Fill the PIV/PIRV/LIVE Form:",
                style: TextStyle(color: Colors.black),
              ),
              trailing: ElevatedButton(
                child: Text(isPIVFormFilled ? "View" : " Form "),
                onPressed: () async {
                  final status = await Get.toNamed(PIVFormsScreen.routeName,
                      arguments: _caseModel.caseId);
                  print("");
                  if (status != null && status == "done") {
                    setState(() {
                      isPIVFormFilled = true;
                    });
                  }
                },
              ),
            ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    final maxLines = 5;
    return Container(
      height: maxLines * 24.0,
      child: TextField(
        //  focusNode: _descFocusNode,
        enabled: !isNotEditable,
        controller: controller,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.headline3,
        decoration: InputDecoration(
          hintText: hint,
          filled: false,
        ),
        onChanged: (text) {},
      ),
    );
  }

  Future<String> _createFolder(String folderPath) async {
    final path = io.Directory(folderPath);
    if ((await path.exists())) {
      return Future.value(path.path);
    } else {
      await path.create();
      return Future.value(path.path);
    }
  }

  Future<io.File> _createSignFileFromString(Uint8List bytes) async {
    io.File file = io.File("$folderPath/" + "sign.png");
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<io.File> _createWaterMarkFileFromString(Uint8List bytes) async {
    io.File file = io.File("$folderPath/" +
        "image_${DateTime.now().millisecondsSinceEpoch.toString()}.png");
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<io.File> _saveFileToAppDirectory(io.File file, CaseDoc caseDoc) async {
    final extension = path.extension(file.path);
    if (caseDoc.docType == DocType.IMAGE) {
      return await file.copy(
          '$folderPath/image_${DateTime.now().millisecondsSinceEpoch.toString()}.png');
    } else if (caseDoc.docType == DocType.VIDEO) {
      return await file.copy(
          '$folderPath/video_${DateTime.now().millisecondsSinceEpoch.toString()}.mp4');
    } else if (caseDoc.docType == DocType.PDF) {
      return await file.copy(
          '$folderPath/PDF_${DateTime.now().millisecondsSinceEpoch.toString()}.pdf');
    } else if (caseDoc.docType == DocType.EXCEL) {
      return await file.copy(
          '$folderPath/excel_${DateTime.now().millisecondsSinceEpoch.toString()}$extension');
    } else if (caseDoc.docType == DocType.SIGNATURE) {
      return await file.copy(
          '$folderPath/sign_${DateTime.now().millisecondsSinceEpoch.toString()}.png');
    } else if (caseDoc.docType == DocType.AUDIO) {
      return await file.copy(
          '$folderPath/audio_${DateTime.now().millisecondsSinceEpoch.toString()}$extension');
    }
    return null;
  }

  Widget _buildSignatureBody() {
    return InkWell(
      child: Container(
          height: 100, child: Center(child: Text('Click here to Sign'))),
      onTap: () {
        _showSignaturePopup();
      },
    );
  }

  _showSignaturePopup() {
    if (isNotEditable) {
      return;
    }
    hideKeyboard();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              height: 410,
              width: SizeConfig.screenWidth * 0.9,
              child: Column(
                children: [
                  Text(
                    "Sign Here",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  //SIGNATURE CANVAS
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)),
                    child: Signature(
                      controller: _controller,
                      height: 300,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        color: Colors.blue,
                        onPressed: () async {
                          Navigator.pop(context);
                          if (_controller.isNotEmpty) {
                            final Uint8List data =
                                await _controller.toPngBytes();
                            if (data != null) {
                              // _signFile = io.File.fromRawPath(data);
                              _signFile = await _createSignFileFromString(data);
                              print(_signFile.path);
                              setState(() {});
                            }
                          }
                        },
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        color: Colors.blue,
                        onPressed: () {
                          setState(() => _controller.clear());
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}
