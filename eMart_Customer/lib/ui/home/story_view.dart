import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/model/story_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/vendorProductsScreen/NewVendorProductsScreen.dart';
import 'package:emartconsumer/utils/network_image_widget.dart';
import 'package:emartconsumer/widget/story_view/controller/story_controller.dart';
import 'package:emartconsumer/widget/story_view/story_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widget/story_view/widgets/story_view.dart';

// ignore: must_be_immutable
class MoreStories extends StatefulWidget {
  final List<StoryModel> storyList;
  int index;

  MoreStories({super.key, required this.index, required this.storyList});

  @override
  MoreStoriesState createState() => MoreStoriesState();
}

class MoreStoriesState extends State<MoreStories> {
  final storyController = StoryController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StoryView(
              storyItems: List.generate(
                widget.storyList[widget.index].videoUrl.length,
                (i) {
                  return StoryItem.pageVideo(
                    widget.storyList[widget.index].videoUrl[i],
                    controller: storyController,
                  );
                },
              ).toList(),
              onComplete: () {
                if (widget.storyList.length - 1 != widget.index) {
                  setState(() {
                    widget.index = widget.index + 1;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              progressPosition: ProgressPosition.top,
              repeat: true,
              controller: storyController,
              onVerticalSwipeComplete: (direction) {
                if (direction == Direction.down) {
                  Navigator.pop(context);
                }
              }),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 30,
                left: 16,
                right: 16),
            child: SizedBox(
              height: 100,
              child: FutureBuilder(
                  future: FireStoreUtils.getVendor(
                      widget.storyList[widget.index].vendorID.toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return loader();
                    } else {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.data == null) {
                        return const SizedBox();
                      } else {
                        VendorModel vendorModel = snapshot.data!;
                        return InkWell(
                          onTap: () {
                            push(
                                context,
                                NewVendorProductsScreen(
                                    vendorModel: vendorModel));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: NetworkImageWidget(
                                  imageUrl: vendorModel.photo.toString(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorModel.title.toString(),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.semiBold),
                                    ),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/ic_star.svg"),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "${calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} reviews",
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: const TextStyle(
                                              color: AppThemeData.warning300,
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily:
                                                  AppThemeData.semiBold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
