import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/network_jitter/network_jitter_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class NetworkJitterOMeter extends StatelessWidget {
  const NetworkJitterOMeter(
    this._networkJitterService, {
    Key? key,
  }) : super(key: key);

  final NetworkJitterController _networkJitterService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Color color;

      final jitter = NetworkJitterController.to?.jitter$ ?? 0;
      color = jitter > 100
          ? AppColors.error
          : jitter > 30
              ? AppColors.pttIdle
              : AppColors.primaryAccent;

      return Row(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
            child: FaIcon(
              Icons.network_check,
              color: color,
              size: 16,
            )),
        RichText(
          text: TextSpan(
            style: AppTheme().typography.bgText4Style,
            children: <TextSpan>[
              TextSpan(
                text:
                    '${_networkJitterService.isOnline$() ? _networkJitterService.jitter$ ?? '000' : '000'}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.jitterChartLine),
              ),
              /* const TextSpan(text: ' [J]',
            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 9),
            ),*/
              const TextSpan(text: ' / '),
              TextSpan(
                text:
                    '${_networkJitterService.isOnline$() ? _networkJitterService.latency ?? '000' : '000'}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.latencyChartLine),
              ),
              /*const TextSpan(text: ' [A]',
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 9)),*/
            ],
          ),
        )
      ]);
    });
  }
}
