import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/model/document_model.dart';
import 'package:emartstore/model/driver_document_model.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/ui/online_registration/details_upload_screen.dart';
import 'package:flutter/material.dart';

class OnlineRegistrationScreen extends StatefulWidget {
  const OnlineRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<OnlineRegistrationScreen> createState() => _OnlineRegistrationScreenState();
}

class _OnlineRegistrationScreenState extends State<OnlineRegistrationScreen> {
  bool isLoading = true;
  List<DocumentModel> documentList = [];
  List<Documents> driverDocumentList = [];

  getDocument() async {
    isLoading = true;
    await FireStoreUtils.getDocumentList().then((value) {
      documentList = value;
      setState(() {
        isLoading = false;
      });
    });

    await FireStoreUtils.getDocumentOfDriver().then((value) {
      if (value != null) {
        setState(() {
          driverDocumentList = value.documents!;
        });
      }
    });
  }

  @override
  void initState() {
    getDocument();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => getDocument(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: documentList.isEmpty
                    ? Center(
                        child: Text("Document not available"),
                      )
                    : ListView.builder(
                        itemCount: documentList.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          DocumentModel documentModel = documentList[index];
                          Documents documents = Documents();
                          var contain = driverDocumentList.where((element) => element.documentId == documentModel.id);
                          if (contain.isNotEmpty) {
                            documents = driverDocumentList.firstWhere((itemToCheck) => itemToCheck.documentId == documentModel.id);
                          }
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(new MaterialPageRoute(builder: (context) => DetailsUploadScreen(documentModel: documentModel))).then((value) {
                                if (value == true) {
                                  getDocument();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white,
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                  border: Border.all(color: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white, width: 0.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Text(
                                            documentModel.title.toString(),
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          )),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey)
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: documents.status == "approved"
                                                ? Colors.green
                                                : documents.status == "rejected"
                                                    ? Colors.red
                                                    : Colors.orange,
                                            borderRadius: BorderRadius.all(Radius.circular(10))),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          child: Text(
                                            documents.status == "approved"
                                                ? "Verified".tr()
                                                : documents.status == "rejected"
                                                    ? "Rejected".tr()
                                                    : documents.status == "uploaded"
                                                        ? "Uploaded".tr()
                                                        : "Pending".tr(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
