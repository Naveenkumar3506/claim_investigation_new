import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/screen/forms_piv.dart';
import 'package:claim_investigation/screen/full_image_screen.dart';
import 'package:claim_investigation/screen/pdfView_screen.dart';
import 'package:claim_investigation/util/app_helper.dart';
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
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:claim_investigation/util/color_contants.dart';

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
    _caseModel = Get.arguments;
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

    //
    listImageDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.IMAGE)
            .toList()
        : [];
    listVideoDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.VIDEO)
            .toList()
        : [];
    listPDFDoc = _caseModel.caseDocs != null
        ? _caseModel.caseDocs
            .where((element) => element.docType == DocType.PDF)
            .toList()
        : [];

    if (_caseModel.caseDocs != null &&
        _caseModel.caseDocs
            .where((element) => element.docType == DocType.PDF)
            .toList()
            .isNotEmpty) {}
    //

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
    });
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
    // bool _validAudioURL = Uri.parse(_caseModel.audioFilePath).isAbsolute;
    if (_audioFile != null) {
      await audioPlayer.play(_audioFile.path, isLocal: true);
    } else if (_current != null) {
      await audioPlayer.play(_current.path, isLocal: true);
    }
    // else if (_caseModel. != null &&
    // _caseModel.audioFilePath.isNotEmpty &&
    // _validAudioURL) {
    //   await audioPlayer.play(Uri.encodeFull(_caseModel.audioFilePath));
    // }
  }

  void onStopAudio() async {
    if (audioPlayer != null) {
      audioPlayer.stop();
    }
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
                          Text('IntimationType : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                              _caseModel.intimationType != null
                                  ? '${_caseModel.intimationType}'
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
                              _caseModel.investigation != null
                                  ? '${_caseModel.investigation.investigationType}'
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
                            Text('Insured DOD : ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                            Text(
                                _caseModel.insuredDod == null
                                    ? "-"
                                    : '${dateFormatter.format(_caseModel.insuredDod)}',
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
                        // _onSubmitReport();
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
                              // saveDraft();
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
                              final thumbnail =
                                  await VideoThumbnail.thumbnailData(
                                video: file.path,
                                imageFormat: ImageFormat.JPEG,
                                maxWidth: 500,
                                quality: 25,
                              );
                              setState(() {
                                var newVideo = CaseDoc();
                                newVideo.isURL = false;
                                newVideo.docName = file.path;
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
                          Positioned(top: 110, child: Text("Added PDF")),
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
                            final _pdfFile = io.File(result.files.single.path);
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
                    }
                  );
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
      child: _caseModel.intimationType == 'CDP'
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
                        _caseModel.intimationType == 'CDP'
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
                      if (_caseModel.intimationType == 'CDP') {
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
                      arguments:
                          Provider.of<ClaimProvider>(context, listen: false)
                              .pivAnswers);
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
