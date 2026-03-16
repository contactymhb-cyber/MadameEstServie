import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/document_model.dart';
import 'package:emartstore/model/driver_document_model.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class DetailsUploadScreen extends StatefulWidget {
  final DocumentModel documentModel;

  const DetailsUploadScreen({Key? key, required this.documentModel}) : super(key: key);

  @override
  State<DetailsUploadScreen> createState() => _DetailsUploadScreenState();
}

class _DetailsUploadScreenState extends State<DetailsUploadScreen> {
  @override
  void initState() {
    // TODO: implement initState
    documentModel = widget.documentModel;
    getDocument();
    setState(() {});
    super.initState();
  }

  DocumentModel documentModel = DocumentModel();

  String frontImage = "";
  String backImage = "";

  bool isLoading = true;

  Documents documents = Documents();

  getDocument() async {
    await FireStoreUtils.getDocumentOfDriver().then((value) {
      isLoading = false;
      if (value != null) {
        var contain = value.documents!.where((element) => element.documentId == documentModel.id);
        if (contain.isNotEmpty) {
          documents = value.documents!.firstWhere((itemToCheck) => itemToCheck.documentId == documentModel.id);
          frontImage = documents.frontImage!;
          backImage = documents.backImage!;
        }
      }
    });
    setState(() {});
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source, required String type}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Navigator.pop(context);
      if (type == "front") {
        frontImage = image.path;
      } else {
        backImage = image.path;
      }
      setState(() {});
    } on PlatformException catch (e) {
      final snack = SnackBar(
        content: Text(
          'Failed to Pick : \n $e'.tr(),
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black,
      );
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
  }

  uploadDocument() async {
    String frontImageFileName = File(frontImage).path.split('/').last;
    String backImageFileName = File(backImage).path.split('/').last;

    if (frontImage.isNotEmpty && hasValidUrl(frontImage) == false) {
      frontImage = await uploadUserImageToFireStorage(File(frontImage), "driverDocument/${MyAppState.currentUser!.userID}", frontImageFileName);
    }

    if (backImage.isNotEmpty && hasValidUrl(backImage) == false) {
      backImage = await uploadUserImageToFireStorage(File(backImage), "driverDocument/${MyAppState.currentUser!.userID}", backImageFileName);
    }
    documents.frontImage = frontImage;
    documents.documentId = documentModel.id;
    documents.backImage = backImage;
    documents.status = "uploaded";

    await FireStoreUtils.uploadDriverDocument(documents).then((value) {
      if (value) {
        ShowToastDialog.closeLoader();
        final snack = SnackBar(
          content: Text(
            'Document upload successfully'.tr(),
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black,
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          documentModel.title.toString(),
          style: TextStyle(color: Colors.black),
        ),
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
            )),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Visibility(
                    visible: documentModel.frontSide == true ? true : false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Front Side of ${documentModel.title.toString()}".tr(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          frontImage.isNotEmpty
                              ? InkWell(
                                  onTap: () {
                                    if (documents.status == "rejected") {
                                      buildBottomSheet(context, "front");
                                    }
                                  },
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * (22 / 100),
                                    width: MediaQuery.of(context).size.width * (90 / 100),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                                      child: hasValidUrl(frontImage) == false
                                          ? Image.file(
                                              File(frontImage),
                                              height: MediaQuery.of(context).size.height * (20 / 100),
                                              width: MediaQuery.of(context).size.width * (80 / 100),
                                              fit: BoxFit.fill,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: frontImage.toString(),
                                              fit: BoxFit.fill,
                                              height: MediaQuery.of(context).size.height * (20 / 100),
                                              width: MediaQuery.of(context).size.width * (80 / 100),
                                              placeholder: (context, url) => Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                              errorWidget: (context, url, error) => Image.network(
                                                  'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                                            ),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    buildBottomSheet(context, "front");
                                  },
                                  child: DottedBorder(
                                    borderType: BorderType.RRect,
                                    radius: const Radius.circular(12),
                                    dashPattern: const [6, 6, 6, 6],
                                    child: SizedBox(
                                        height: MediaQuery.of(context).size.height * (20 / 100),
                                        width: MediaQuery.of(context).size.width * (90 / 100),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context).size.height * (8 / 100),
                                              width: MediaQuery.of(context).size.width * (20 / 100),
                                              decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(10))),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Image.asset(
                                                  'assets/images/document_placeholder.png',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text("Add photo".tr())
                                          ],
                                        )),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: documentModel.backSide == true ? true : false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Back side of ${documentModel.title.toString()}".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(
                            height: 10,
                          ),
                          backImage.isNotEmpty
                              ? InkWell(
                                  onTap: () {
                                    if (documents.status == "uploaded" || documents.status == "rejected") {
                                      buildBottomSheet(context, "back");
                                    }
                                  },
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * (20 / 100),
                                    width: MediaQuery.of(context).size.width * (90 / 100),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                                      child: hasValidUrl(backImage) == false
                                          ? Image.file(
                                              File(backImage),
                                              height: MediaQuery.of(context).size.height * (20 / 100),
                                              width: MediaQuery.of(context).size.width * (80 / 100),
                                              fit: BoxFit.fill,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: backImage.toString(),
                                              fit: BoxFit.fill,
                                              height: MediaQuery.of(context).size.height * (20 / 100),
                                              width: MediaQuery.of(context).size.width * (80 / 100),
                                              placeholder: (context, url) => Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                              errorWidget: (context, url, error) => Image.network(
                                                  'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                                            ),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    buildBottomSheet(context, "back");
                                  },
                                  child: DottedBorder(
                                    borderType: BorderType.RRect,
                                    radius: const Radius.circular(12),
                                    dashPattern: const [6, 6, 6, 6],
                                    child: SizedBox(
                                        height: MediaQuery.of(context).size.height * (20 / 100),
                                        width: MediaQuery.of(context).size.width * (90 / 100),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context).size.height * (8 / 100),
                                              width: MediaQuery.of(context).size.width * (20 / 100),
                                              decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(10))),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Image.asset(
                                                  'assets/images/document_placeholder.png',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text("Add photo".tr())
                                          ],
                                        )),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Visibility(
                    visible: documents.status == "approved" || documents.status == "uploaded" ? false : true,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: double.infinity),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(COLOR_PRIMARY),
                            padding: EdgeInsets.only(top: 12, bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              side: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                          ),
                          child: Text(
                            'Upload Document'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode(context) ? Colors.black : Colors.white,
                            ),
                          ),
                          onPressed: () {
                            if (documentModel.frontSide == true && frontImage.isEmpty) {
                              final snack = SnackBar(
                                content: Text(
                                  'Please upload front side of document.'.tr(),
                                  style: TextStyle(color: Colors.white),
                                ),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.black,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snack);
                            } else if (documentModel.backSide == true && backImage.isEmpty) {
                              final snack = SnackBar(
                                content: Text(
                                  'Please upload back side of document.'.tr(),
                                  style: TextStyle(color: Colors.white),
                                ),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.black,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snack);
                            } else {
                              ShowToastDialog.showLoader("Please wait..");
                              uploadDocument();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  buildBottomSheet(BuildContext context, String type) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      "Please Select".tr(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(source: ImageSource.camera, type: type),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                )),
                            Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Text("Camera".tr()),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(source: ImageSource.gallery, type: type),
                                icon: const Icon(
                                  Icons.photo_library_sharp,
                                  size: 32,
                                )),
                            Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Text("Gallery".tr()),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }
}
