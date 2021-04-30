import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class FullImageViewScreen extends StatefulWidget {
  static const routeName = '/fullImageViewScreen';
  @override
  _FullImageViewScreenState createState() => _FullImageViewScreenState();
}

class _FullImageViewScreenState extends State<FullImageViewScreen> {
  @override
  Widget build(BuildContext context) {
   Map<String,dynamic> arguments =   Get.arguments;
    String imageUrl = arguments['IMAGE'];
    String key = arguments['KEY'];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: (){
              Get.close(1);
            },
          )
        ],
      ),
      body: InkWell(
        onTap: () {
          Get.back();
        },
        child: Container(
            child: PhotoView(
         // minScale: 1.0,
          maxScale: 5.0,
          imageProvider: CachedNetworkImageProvider(
            imageUrl,
          ),
        )),
      ),
    );
  }
}
