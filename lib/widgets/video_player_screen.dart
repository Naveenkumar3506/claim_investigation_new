import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);
  static const routeName = '/videoPlayScreen';

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    Map<String, dynamic> arguments = Get.arguments;

    if (arguments != null && arguments['file'] != null) {
      _controller = VideoPlayerController.file(arguments['file']);
      _initializeVideoPlayerFuture = _controller.initialize();
      _controller.setLooping(false);
      _controller.play();
    } else if (arguments != null && arguments['videoURL'] != null) {
      _controller = VideoPlayerController.network(arguments['videoURL']);
      _initializeVideoPlayerFuture = _controller.initialize().then((value) {
        _controller.setLooping(false);
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
        _controller.play();
      });
    }

    _controller.addListener(() {
      setState(() {});
    });

    // Initialize the controller and store the Future for later use.

    // Use the controller to loop the video.
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller.value.isPlaying) {
          _controller.pause();
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(),
        body: ModalProgressHUD(
          inAsyncCall: _controller.value.isBuffering,
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the VideoPlayerController has finished initialization, use
                // the data it provides to limit the aspect ratio of the video.
                return Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                );
              } else {
                // If the VideoPlayerController is still initializing, show a
                // loading spinner.
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black87,
          onPressed: () async {
            // If the video is playing, pause it.
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              // If the video is paused, play it.
              if (_controller.value.position == _controller.value.duration) {
                await _controller.seekTo(Duration.zero);
                setState(() {
                  _controller.play();
                });
              } else {
                _controller.play();
              }
            }
            setState(() {});
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }
}
