import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/theme/app_them_data.dart';
import 'package:emartconsumer/ui/dineInScreen/HistoryTableBooking.dart';
import 'package:emartconsumer/ui/dineInScreen/UpComingTableBooking.dart';
import 'package:flutter/material.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  List<Widget> list = [
    Tab(text: "Upcoming".tr()),
    Tab(text: "History".tr()),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
          appBar: TabBar(
            labelColor: AppThemeData.primary300,
            indicatorColor: AppThemeData.primary300,
            unselectedLabelColor: const Color(GREY_TEXT_COLOR),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: list,
          ),
          body: const TabBarView(children: [
            UpComingTableBooking(),
            HistoryTableBooking(),
          ])),
    );
  }
}
