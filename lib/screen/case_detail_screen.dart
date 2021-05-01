import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:claim_investigation/base/base_page.dart';
import 'package:claim_investigation/models/case_model.dart';
import 'package:claim_investigation/providers/claim_provider.dart';
import 'package:claim_investigation/providers/multipart_upload_provider.dart';
import 'package:claim_investigation/screen/full_image_screen.dart';
import 'package:claim_investigation/screen/pdfView_screen.dart';
import 'package:claim_investigation/util/app_enum.dart';
import 'package:claim_investigation/util/app_helper.dart';
import 'package:claim_investigation/util/color_contants.dart';
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
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CaseDetailScreen extends BasePage {
  static const routeName = '/caseDetailScreen';

  @override
  _CaseDetailScreenState createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends BaseState<CaseDetailScreen> {
  CaseModel _caseModel;
  final formatCurrency = new NumberFormat.simpleCurrency(locale: 'en_IN');
  final dateFormatter = DateFormat('dd/MM/yyyy');
  final _descFocusNode = FocusNode();
  TextEditingController descTextController = TextEditingController();
  TextEditingController remarksTextController = TextEditingController();
  TextEditingController pdfName1TextController = TextEditingController();
  TextEditingController pdfName2TextController = TextEditingController();
  TextEditingController pdfName3TextController = TextEditingController();
  TextEditingController documentTextController = TextEditingController();
  io.File _imageFile,
      _videoFile,
      _pdfFile1,
      _pdfFile2,
      _pdfFile3,
      _signFile,
      _documentFile,
      _audioFile;
  Uint8List _thumbnail;
  String _pdfFileName1, _pdfFileName2, _pdfFileName3, _documentFileName;
  Timer timer;
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Initialized;
  final LocalFileSystem localFileSystem = LocalFileSystem();
  AudioPlayer audioPlayer;
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool isNotEditable = false;
  String videoThumbnailPath;
  AudioPlayerState audioPlayerState;

  @override
  void initState() {
    _caseModel = Get.arguments;
    descTextController.text = _caseModel.caseDescription;
    super.initState();
    _initAudioRecording();
    _controller.addListener(() => print("Value changed"));
    if (_caseModel.caseStatus.toLowerCase() == "closed".toLowerCase()) {
      isNotEditable = true;
      //
      if (_caseModel.pdf1FilePath != null &&
          _caseModel.pdf1FilePath.isNotEmpty) {
        pdfName1TextController.text = 'PDF 1';
      }
      if (_caseModel.pdf2FilePath != null &&
          _caseModel.pdf2FilePath.isNotEmpty) {
        pdfName2TextController.text = 'PDF 2';
      }
      if (_caseModel.pdf3FilePath != null &&
          _caseModel.pdf3FilePath.isNotEmpty) {
        pdfName3TextController.text = 'PDF 3';
      }
      if (_caseModel.excelFilepath != null &&
          _caseModel.excelFilepath.isNotEmpty) {
        documentTextController.text = 'Excel';
      }
    }

    try {
      new Future.delayed(Duration(milliseconds: 500), () async {
        await VideoThumbnail.thumbnailFile(
          video: Uri.encodeFull(_caseModel.videoFilePath),
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          // maxHeight: 64,
          // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
          quality: 75,
        ).then((value) {
          setState(() {
            videoThumbnailPath = value;
          });
        });
      });
    } on Exception catch (exception) {
      print(exception.toString());
    } catch (error) {
      print(error.toString());
    }
  }

  @override
  void dispose() {
    _descFocusNode.dispose();
    timer?.cancel();
    audioPlayer.pause();
    audioPlayer.dispose();
    super.dispose();
  }

  Future _initAudioRecording() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
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
    print("File length: ${await _audioFile.length()}");
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
    if (_caseModel.audioFilePath != null &&
        _caseModel.audioFilePath.isNotEmpty) {
      await audioPlayer.play(Uri.encodeFull(_caseModel.audioFilePath));
    } else {
      await audioPlayer.play(_current.path, isLocal: true);
    }
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
      showAdaptiveAlertDialog(
        context: context,
        title: "Alert",
        content: "Location is mandatory.",
        defaultActionText: "Settings",
        cancelActionText: "Cancel",
        defaultAction: () {
          Geolocator.openAppSettings();
        },
      );
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<bool> uploadImage() async {
    if (_imageFile != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_imageFile, MimeMediaType.image, _caseModel, 'image');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadVideo() async {
    if (_videoFile != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_videoFile, MimeMediaType.video, _caseModel, 'video');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadAudio() async {
    if (_audioFile != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_audioFile, MimeMediaType.audio, _caseModel, 'audio');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF1() async {
    if (_pdfFile1 != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_pdfFile1, MimeMediaType.pdf, _caseModel, 'pdf1');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF2() async {
    if (_pdfFile2 != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_pdfFile2, MimeMediaType.pdf, _caseModel, 'pdf2');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadPDF3() async {
    if (_pdfFile3 != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_pdfFile3, MimeMediaType.pdf, _caseModel, 'pdf3');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadDocument() async {
    if (_documentFile != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_documentFile, MimeMediaType.excel, _caseModel, 'excel');
    } else {
      return Future.value(true);
    }
  }

  Future<bool> uploadSign() async {
    if (_signFile != null) {
      return await Provider.of<MultiPartUploadProvider>(context, listen: false)
          .uploadFile(_signFile, MimeMediaType.image, _caseModel, 'sign');
    } else {
      return Future.value(true);
    }
  }

  Future _onSubmitReport() async {
    if (isNotEditable) {
      return;
    }
    await _determinePosition().then((position) async {
      if (position != null) {
        print('got');
        _caseModel.caseDescription = descTextController.text;
        _caseModel.latitude = position.latitude.toString();
        _caseModel.longitude = position.longitude.toString();
        _caseModel.newRemarks = remarksTextController.text;

        showLoadingDialog();
        var uploadCount = 0;
        var resultCount = 0;

        final results = await Future.wait([
          // uploadImage(),
          // uploadPDF1(),
          // uploadPDF2(),
          // uploadPDF3(),
          uploadSign(),
          // uploadDocument(),
          // uploadAudio(),
          // uploadVideo()
        ]);

        // if (_imageFile != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_imageFile, MimeMediaType.image, _caseModel, 'image')
        //       .then((isImageSuccess) async {
        //     resultCount++;
        //   });
        // }
        // if (_audioFile != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_audioFile, MimeMediaType.audio, _caseModel, 'audio')
        //       .then((isImageSuccess) async {
        //     resultCount++;
        //   });
        // }
        // if (_pdfFile1 != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_pdfFile1, MimeMediaType.pdf, _caseModel, 'pdf1')
        //       .then((isPDF1Success) {
        //     resultCount++;
        //   });
        // }
        // if (_pdfFile2 != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_pdfFile2, MimeMediaType.pdf, _caseModel, 'pdf2')
        //       .then((isPDF2Success) {
        //     resultCount++;
        //   });
        // }
        // if (_pdfFile3 != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_pdfFile3, MimeMediaType.pdf, _caseModel, 'pdf3')
        //       .then((isPDF3Success) {
        //     resultCount++;
        //   });
        // }
        // if (_documentFile != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(
        //           _documentFile, MimeMediaType.excel, _caseModel, 'excel')
        //       .then((isPDF3Success) {
        //     resultCount++;
        //   });
        // }
        // if (_signFile != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_signFile, MimeMediaType.excel, _caseModel, 'sign')
        //       .then((isPDF3Success) {
        //     resultCount++;
        //   });
        // }
        // if (_videoFile != null) {
        //   uploadCount++;
        //   await Provider.of<MultiPartUploadProvider>(context, listen: false)
        //       .uploadFile(_videoFile, MimeMediaType.video, _caseModel, 'video')
        //       .then((isImageSuccess) async {
        //     resultCount++;
        //   });
        // }

        if (resultCount == uploadCount) {
          await Provider.of<ClaimProvider>(context, listen: false)
              .submitReport(_caseModel)
              .then((isSuccess) {
            if (isSuccess) {
              Navigator.pop(context);
              Provider.of<ClaimProvider>(SizeConfig.cxt, listen: false)
                  .getCaseList(true);
              showSuccessToast('Cases Details submitted successfully');
            } else {
              showErrorToast('Oops, Something went wrong. Please try later');
            }
          });
        }
      }
    });
  }

  void _launchURL(String url) async => await canLaunch(Uri.encodeFull(url))
      ? await launch(Uri.encodeFull(url))
      : throw 'Could not launch $url';

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
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text('${formatCurrency.format(_caseModel.sumAssured)}',
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
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text('${_caseModel.intimationType}',
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
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text('${_caseModel.investigation.investigationType}',
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
                        Text('Status : ',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${dateFormatter.format(_caseModel.insuredDob)}',
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
                          Text('Insured DOD : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${dateFormatter.format(_caseModel.insuredDod)}',
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
                          Text('Insured Address : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
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
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text(
                            '${_caseModel.nomineeName}',
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text('Nominee Contact No. : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${_caseModel.nomineeContactNumber}',
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
                          Text('Nominee Address : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
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
                        children: [
                          Text('State : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${_caseModel.location.state}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text('Zone : ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('${_caseModel.location.zone.trim()}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
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
              _caseModel.remarks.isEmpty || _caseModel.remarks == null
                  ? Container()
                  : Card(
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
                    ),
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
            ],
          ),
        ),
      ),
    );
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
                        onPressed: () {
                          onStopAudio();
                          switch (_currentStatus) {
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
    return Card(
      child: ListTile(
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
                  'PDF Attachments : ',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                _pdfFile1 != null || _pdfFile2 != null || _pdfFile3 != null
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            _pdfFile1 = null;
                            _pdfFile2 = null;
                            _pdfFile3 = null;
                            //
                            _pdfFileName1 = '';
                            _pdfFileName2 = '';
                            _pdfFileName3 = '';
                            //
                            pdfName1TextController.text = "";
                            pdfName2TextController.text = "";
                            pdfName3TextController.text = "";
                          });
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      )
                    : Container()
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: pdfName1TextController,
                    enabled: true,
                    readOnly: true,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headline3,
                    decoration: InputDecoration(
                        hintText: "Select PDF 1",
                        filled: false,
                        suffixIcon: _pdfFile1 != null
                            ? InkWell(
                                onTap: () {
                                  setState(() {
                                    _pdfFile1 = null;
                                    _pdfFileName1 = '';
                                    //
                                    pdfName1TextController.text = "";
                                  });
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              )
                            : null),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isNotEditable) {
                      if (_caseModel.pdf1FilePath != null) {
                        Get.toNamed(PDFViewerCachedFromUrl.routeName,
                            arguments: {"url": _caseModel.pdf1FilePath});
                      }
                      return;
                    }
                    FilePickerResult result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            allowCompression: true);
                    if (result != null) {
                      setState(() {
                        PlatformFile platformFile = result.files.first;
                        if (platformFile.extension == "pdf") {
                          _pdfFile1 = io.File(result.files.single.path);
                          _pdfFileName1 = platformFile.name;
                          pdfName1TextController.text = _pdfFileName1;
                        } else {
                          Get.snackbar(
                              'Alert', 'Please select PDF files only.');
                        }
                      });
                    } else {
                      // User canceled the picker
                    }
                  },
                  child: Text(isNotEditable &&
                          _caseModel.pdf1FilePath != null &&
                          _caseModel.pdf1FilePath.isNotEmpty
                      ? 'View'
                      : 'Select'),
                )
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: pdfName2TextController,
                    enabled: true,
                    readOnly: true,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headline3,
                    decoration: InputDecoration(
                        hintText: "Select PDF 2",
                        filled: false,
                        suffixIcon: _pdfFile2 != null
                            ? InkWell(
                                onTap: () {
                                  setState(() {
                                    _pdfFile2 = null;
                                    _pdfFileName2 = '';
                                    //
                                    pdfName2TextController.text = "";
                                  });
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              )
                            : null),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isNotEditable) {
                      if (_caseModel.pdf2FilePath != null) {
                        Get.toNamed(PDFViewerCachedFromUrl.routeName,
                            arguments: {"url": _caseModel.pdf2FilePath});
                      }
                      return;
                    }
                    FilePickerResult result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            allowCompression: true);
                    if (result != null) {
                      setState(() {
                        PlatformFile platformFile = result.files.first;
                        if (platformFile.extension == "pdf") {
                          _pdfFile2 = io.File(result.files.single.path);
                          _pdfFileName2 = platformFile.name;
                          pdfName2TextController.text = _pdfFileName2;
                        } else {
                          Get.snackbar(
                              'Alert', 'Please select PDF files only.');
                        }
                      });
                    } else {
                      // User canceled the picker
                    }
                  },
                  child: Text(isNotEditable &&
                          _caseModel.pdf2FilePath != null &&
                          _caseModel.pdf2FilePath.isNotEmpty
                      ? 'View'
                      : 'Select'),
                )
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: pdfName3TextController,
                    enabled: true,
                    readOnly: true,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headline3,
                    decoration: InputDecoration(
                        hintText: "Select PDF 3",
                        filled: false,
                        suffixIcon: _pdfFile3 != null
                            ? InkWell(
                                onTap: () {
                                  setState(() {
                                    _pdfFile3 = null;
                                    _pdfFileName3 = '';
                                    //
                                    pdfName3TextController.text = "";
                                  });
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              )
                            : null),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isNotEditable) {
                      if (_caseModel.pdf3FilePath != null) {
                        Get.toNamed(PDFViewerCachedFromUrl.routeName,
                            arguments: {"url": _caseModel.pdf3FilePath});
                      }
                      return;
                    }
                    FilePickerResult result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            allowCompression: true);

                    if (result != null) {
                      setState(() {
                        PlatformFile platformFile = result.files.first;
                        if (platformFile.extension == "pdf") {
                          _pdfFile3 = io.File(result.files.single.path);
                          _pdfFileName3 = platformFile.name;
                          pdfName3TextController.text = _pdfFileName3;
                        } else {
                          Get.snackbar(
                              'Alert', 'Please select PDF files only.');
                        }
                      });
                    } else {
                      // User canceled the picker
                    }
                  },
                  child: Text(isNotEditable &&
                          _caseModel.pdf3FilePath != null &&
                          _caseModel.pdf3FilePath.isNotEmpty
                      ? 'View'
                      : 'Select'),
                )
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

  Widget _buildImageAndVideo() {
    return Padding(
      padding: EdgeInsets.all(15.0),
      child: Column(
        children: [
          SizedBox(
            width: SizeConfig.screenWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UPLOAD IMAGE',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                _imageFile != null
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            _imageFile = null;
                          });
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      )
                    : Container()
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            children: [
              InkWell(
                onTap: () {
                  if (isNotEditable) {
                    if (_caseModel.image != null &&
                        _caseModel.image.isNotEmpty) {
                      Get.toNamed(FullImageViewScreen.routeName, arguments: {
                        'IMAGE': _caseModel.image,
                      });
                    }
                    return;
                  }
                  imagePickerDialog(() async {
                    //camera
                    await getImageFile(ImageSource.camera).then((value) {
                      if (value != null) {
                        setState(() {
                          _imageFile = value;
                        });
                      }
                    });
                  }, () async {
                    //gallery
                    await getImageFile(ImageSource.gallery).then((value) {
                      if (value != null) {
                        setState(() {
                          _imageFile = value;
                        });
                      }
                    });
                  });
                },
                child: _caseModel.image != null && _caseModel.image.isNotEmpty
                    ? SizedBox(
                        height: SizeConfig.screenHeight * .3,
                        width: SizeConfig.screenWidth,
                        child: CachedNetworkImage(
                          imageUrl: _caseModel.image,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _imageFile == null
                        ? Stack(alignment: Alignment.center, children: [
                            Container(
                              height: SizeConfig.screenHeight * .3,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey)),
                            ),
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Image.asset(
                                'assets/images/ic_image_upload_placeholder.png',
                              ),
                            ),
                            Positioned(
                                top: (SizeConfig.screenHeight * .3) / 2 + 60,
                                child: Text("Upload Image"))
                          ])
                        : SizedBox(
                            height: SizeConfig.screenHeight * .3,
                            width: SizeConfig.screenWidth,
                            child: Image.file(
                              _imageFile,
                              fit: BoxFit.cover,
                            ),
                          ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            width: SizeConfig.screenWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UPLOAD VIDEO (MAX 5 MIN)',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                _videoFile != null
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            _videoFile = null;
                          });
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      )
                    : Container()
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            children: [
              InkWell(
                onTap: () {
                  if (isNotEditable) {
                    return;
                  }
                  videoPickerDialog(() async {
                    //camera
                    await getVideoFile(ImageSource.camera).then((file) async {
                      if (file != null) {
                        _thumbnail = await VideoThumbnail.thumbnailData(
                          video: file.path,
                          imageFormat: ImageFormat.JPEG,
                          maxWidth: 500,
                          quality: 25,
                        );
                        setState(() {
                          _videoFile = file;
                        });
                      }
                    });
                  }, () async {
                    //gallery
                    await getVideoFile(ImageSource.gallery).then((file) async {
                      if (file != null) {
                        _thumbnail = await VideoThumbnail.thumbnailData(
                          video: file.path,
                          imageFormat: ImageFormat.JPEG,
                          maxWidth: 500,
                          quality: 25,
                        );
                        setState(() {
                          _videoFile = file;
                        });
                      }
                    });
                  });
                },
                child: videoThumbnailPath != null &&
                        videoThumbnailPath.isNotEmpty
                    ? SizedBox(
                        height: SizeConfig.screenHeight * .3,
                        width: SizeConfig.screenWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.file(
                              io.File(videoThumbnailPath),
                              fit: BoxFit.fill,
                            ),
                            InkWell(
                              child: Icon(
                                Icons.play_circle_filled_sharp,
                                color: Theme.of(context).primaryColor,
                                size: 70,
                              ),
                              onTap: () {
                                Get.toNamed(VideoPlayerScreen.routeName,
                                    arguments: {
                                      'file': _videoFile,
                                      'videoURL': Uri.encodeFull(
                                          _caseModel.videoFilePath)
                                    });
                              },
                            ),
                          ],
                        ),
                      )
                    : _videoFile == null
                        ? Stack(alignment: Alignment.center, children: [
                            Container(
                              height: SizeConfig.screenHeight * .3,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey)),
                            ),
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Image.asset(
                                'assets/images/ic_video_upload_placeholder.png',
                              ),
                            ),
                            Positioned(
                                top: (SizeConfig.screenHeight * .3) / 2 + 60,
                                child: Text("Upload Video"))
                          ])
                        : SizedBox(
                            height: SizeConfig.screenHeight * .3,
                            width: SizeConfig.screenWidth,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.memory(
                                  _thumbnail,
                                  fit: BoxFit.fill,
                                ),
                                InkWell(
                                  child: Icon(
                                    Icons.play_circle_filled_sharp,
                                    color: Theme.of(context).primaryColor,
                                    size: 70,
                                  ),
                                  onTap: () {
                                    Get.toNamed(VideoPlayerScreen.routeName,
                                        arguments: {'file': _videoFile});
                                  },
                                ),
                              ],
                            ),
                          ),
              )
            ],
          ),
        ],
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
                            final Uint8List data = await _controller.toPngBytes();
                            if (data != null) {
                              _signFile = io.File.fromRawPath(data);
                              setState(() {
                              });
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

  Widget _buildClaimFormatBody() {
    return Card(
      child: ListTile(
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
                  final ByteData bytes =
                      await rootBundle.load('assets/images/ClaimForm.xlsx');
                  if (io.Platform.isAndroid) {
                    String dir =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS);
                    io.File file = new io.File('$dir/ClaimForm.xlsx');
                    await file
                        .writeAsBytes(bytes.buffer.asUint8List())
                        .then((value) {
                      showSuccessToast('Saved to downloads');
                    });
                  } else {
                    await Share.file('Doc', 'ClaimForm.xlsx',
                        bytes.buffer.asUint8List(), 'application/vnd.ms-excel',
                        text: 'Claim Form format for document collection');
                  }
                } else {
                  final ByteData bytes =
                      await rootBundle.load('assets/images/PIVReport.xls');
                  if (io.Platform.isAndroid) {
                    String dir =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS);
                    io.File file = new io.File('$dir/PIVReport.xls');
                    await file
                        .writeAsBytes(bytes.buffer.asUint8List())
                        .then((value) {
                      showSuccessToast('Saved to downloads');
                    });
                  } else {
                    await Share.file('Doc', 'PIVReport.xls',
                        bytes.buffer.asUint8List(), 'application/vnd.ms-excel',
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
                      if (_caseModel.excelFilepath != null &&
                          _caseModel.excelFilepath.isNotEmpty) {
                        showLoadingDialog(hint: "Downloading...");
                        await Provider.of<ClaimProvider>(context, listen: false)
                            .downloadFile(_caseModel.excelFilepath,
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
                          _documentFile = io.File(result.files.single.path);
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
                          _caseModel.excelFilepath != null &&
                          _caseModel.excelFilepath.isNotEmpty
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
      ),
    );
  }
}
