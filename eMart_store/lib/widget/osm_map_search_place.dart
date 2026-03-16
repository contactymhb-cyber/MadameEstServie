
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/theme/app_them_data.dart';
import 'package:emartstore/theme/text_field_widget.dart';
import 'package:emartstore/widget/osm_search_place_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class OsmSearchPlacesApi extends StatelessWidget {
  const OsmSearchPlacesApi({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: OsmSearchPlaceController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppThemeData.primary300,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey50,
                ),
              ),
              title: Text(
                'Search Places'.tr,
                style: TextStyle(
                  color: isDarkMode(context) ? AppThemeData.grey50 : AppThemeData.grey50,
                  fontSize: 16,
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  TextFieldWidget(
                    controller: controller.searchTxtController.value,
                    hintText: 'Search your location here'.tr,
                    suffix: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        controller.searchTxtController.value.clear();
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      primary: true,
                      itemCount: controller.suggestionsList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(controller.suggestionsList[index].address.toString()),
                          onTap: () {
                            Navigator.pop(context,controller.suggestionsList[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
