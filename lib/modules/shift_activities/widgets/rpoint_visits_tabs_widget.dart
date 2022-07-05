import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/rpoint_info_window_visit_list_widget.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RPointVisitsTabsWidget extends StatefulWidget {
  const RPointVisitsTabsWidget({Key? key, required this.rPoint})
      : super(key: key);
  final ReportingPoint rPoint;

  @override
  _RPointVisitsTabsWidgetState createState() => _RPointVisitsTabsWidgetState();
}

class _RPointVisitsTabsWidgetState extends State<RPointVisitsTabsWidget>
    with TickerProviderStateMixin {
  TabController? _controller;
  List<Tab> tabs = <Tab>[];
  final controller = ShiftActivitiesStatsController.to;
  List<List<ReportingPointVisit>> tabsContent = [];

  @override
  void initState() {
    final filteredTours = controller.tours.where((tour) {
      return tour.path.any((tp) =>
          tp.reportingPoint.id == widget.rPoint.id &&
          tp.reportingPoint.hasVisits);
    }).toList();

    tabs = filteredTours.asMap().entries.map((e) {
      return Tab(
        child: Text(
          "Tour ${e.key + 1}",
          style: AppTheme().typography.listItemTitleStyle,
        ),
      );
    }).toList();
    final targetRPoint = controller.unplannedRPoints.firstWhere(
        (rp) => rp.id == widget.rPoint.id && rp.hasVisits,
        orElse: () => null!);
    if (targetRPoint != null) {
      tabs.insert(
        0,
        Tab(
          child: Text(
            'Unplanned',
            style: AppTheme().typography.bgTitle2Style,
          ),
        ),
      );
      tabsContent.insert(0, targetRPoint.visits!);
    }

    tabsContent = filteredTours.fold<List<List<ReportingPointVisit>>>(
        [],
        (result, tour) => result
          ..add(tour.path
              .firstWhere((tp) => tp.reportingPoint.id == widget.rPoint.id)
              .reportingPoint
              .visits!));

    _controller = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return Center(
        child: Text(
          "AppLocalizations.of(context).noVisitsYet",
          style: AppTheme().typography.bgText3Style,
        ),
      );
    }
    return Column(
      children: [
        Container(
          height: 30,
          child: TabBar(
            controller: _controller,
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        SizedBox(
          height: 80,
          child: TabBarView(
            controller: _controller,
            children: tabsContent.map((visits) {
              return RPointInfoWindowVisitsList(
                visits: visits,
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}
