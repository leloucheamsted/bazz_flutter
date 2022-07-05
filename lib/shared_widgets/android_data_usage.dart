import 'dart:typed_data';

import 'package:data_usage/data_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bazz_flutter/app_theme.dart';

class Android extends StatelessWidget {
  const Android({
    Key? key,
    required List<DataUsageModel> dataUsage,
    required this.size,
  })  : _dataUsage = dataUsage,
        super(key: key);

  final List<DataUsageModel> _dataUsage;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (_dataUsage != null)
          for (var item in _dataUsage) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  if (item.appIconBytes != null)
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: MemoryImage(item.appIconBytes as Uint8List),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: size.width * 0.7,
                        child: Text(
                          item.appName as String,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme().typography.bgTitle2Style,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: size.width * 0.7,
                        child: Text(
                          item.packageName as String,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme().typography.bgText4Style,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            'Received: ${(item.received! / 1048576).toStringAsFixed(4)}MB  ',
                            style: AppTheme().typography.bgText4Style,
                          ),
                          Text(
                            'Sent: ${(item.sent! / 1048576).toStringAsFixed(4)}MB',
                            style: AppTheme().typography.bgText4Style,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider()
          ]
      ],
    );
  }
}
