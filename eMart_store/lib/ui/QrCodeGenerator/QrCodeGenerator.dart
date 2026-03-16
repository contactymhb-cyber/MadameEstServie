import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/widget/image_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

class QrCodeGenerator extends StatefulWidget {
  const QrCodeGenerator({Key? key, required this.vendorModel}) : super(key: key);

  @override
  State<QrCodeGenerator> createState() => _QrCodeGeneratorState();

  final VendorModel vendorModel;
}

class _QrCodeGeneratorState extends State<QrCodeGenerator> {
  GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "QR Information".tr(),
            style: TextStyle(fontFamily: "Poppins", letterSpacing: 0.5, fontWeight: FontWeight.normal, color: isDarkMode(context) ? Colors.white : Colors.black),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode(context) ? Colors.white : Colors.black,
              size: 40,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ), //isDarkMode(context) ? Color(COLOR_DARK) : null,
        body: Container(
          margin: EdgeInsets.only(left: 10, right: 10),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RepaintBoundary(
                  key: globalKey,
                  child: QrImageView(
                    data: '${widget.vendorModel.id}',
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: AppThemeData.grey50,
                    foregroundColor: AppThemeData.grey900,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "${widget.vendorModel.title}",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontFamily: "Poppinssb", fontSize: 18, letterSpacing: 0.5, fontWeight: FontWeight.normal, color: isDarkMode(context) ? Colors.white : Colors.black),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(COLOR_PRIMARY),
                      ),
                    ),
                    backgroundColor: Color(COLOR_PRIMARY),
                  ),
                  onPressed: () {
                    saveFile(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Download this QR-Code'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveFile(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await ImageSaver.saveImage(byteData.buffer.asUint8List(), "qrcode${DateTime.now().toIso8601String()}.png");
        ShowToastDialog.showToast("Image save successfully".tr());
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
  }
}
