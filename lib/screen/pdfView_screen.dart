import 'package:claim_investigation/widgets/empty_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:get/get.dart';

class PDFViewerCachedFromUrl extends StatefulWidget {
  const PDFViewerCachedFromUrl({Key key}) : super(key: key);
  static const routeName = '/PDFViewerCachedFromUrl';

  @override
  _PDFViewerCachedFromUrlState createState() => _PDFViewerCachedFromUrlState();
}

class _PDFViewerCachedFromUrlState extends State<PDFViewerCachedFromUrl> {
  String url = "";
  String path = "";

  @override
  void initState() {
    if (Get.arguments["url"] != null) {
      url = Get.arguments["url"];
    }
    if (Get.arguments["path"] != null) {
      path = Get.arguments["path"];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: path.isNotEmpty
          ? const PDF().fromPath(
              path,
            )
          : url.isNotEmpty
              ? const PDF().cachedFromUrl(
                  url,
                  placeholder: (double progress) =>
                      Center(child: Text('$progress %')),
                  errorWidget: (dynamic error) =>
                      Center(child: Text(error.toString())),
                )
              : EmptyMessage('No file found'),
    );
  }
}
