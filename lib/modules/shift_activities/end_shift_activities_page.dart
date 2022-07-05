import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/shift_activities_card.dart';
import 'package:bazz_flutter/shared_widgets/timer_and_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

class EndShiftActivitiesPage extends GetView<ShiftActivitiesService> {
  const EndShiftActivitiesPage({Key? key}) : super(key: key);

  static const mockedActivities = [
    {
      'id': '1',
    },
    {
      'id': '2',
    },
    {
      'id': '3',
    },
    {
      'id': '4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        body: Column(
          children: [
            CustomAppBar(withBackButton: true, title: 'End Shift Activities'),
            TimerAndStatusBar(controller: HomeController.to),
            KeyboardVisibilityBuilder(
              builder: (context, visible) {
                if (visible) return const SizedBox();

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 20),
                        color: AppColors.secondaryButton,
                        alignment: Alignment.centerLeft,
                        height: 50,
                        child: Text(
                          'Description',
                          style: AppTypography.subtitle2TextStyle
                              .copyWith(color: AppColors.brightText),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              'perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntura'
                              'perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntura'
                              'perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntura'
                              'perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntura',
                              style: AppTypography.bodyText8TextStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.only(left: 20),
              color: AppColors.error,
              alignment: Alignment.centerLeft,
              height: 50,
              child: Text(
                'Check List',
                style: AppTypography.subtitle2TextStyle
                    .copyWith(color: AppColors.brightText),
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            //   height: 215,
            //   child: ListView.separated(
            //     scrollDirection: Axis.horizontal,
            //     itemBuilder: (context, i) {
            //       return ShiftActivitiesCard(
            //         key: UniqueKey(),
            //         activityId: mockedActivities[i]['id'] as String,
            //         title: 'Check the door $i',
            //       );
            //     },
            //     separatorBuilder: (context, i) => const SizedBox(width: 5),
            //     itemCount: mockedActivities.length,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
