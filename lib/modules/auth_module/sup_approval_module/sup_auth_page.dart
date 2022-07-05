import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/auth_module/sup_approval_module/sup_auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupervisorAuthPage extends GetView<SupervisorAuthController> {
  const SupervisorAuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppTheme().colors.appBar,
        iconTheme: const IconThemeData(
          color: AppColors.primaryAccent,
        ),
        // leading: ,
      ),
      body: const Center(
        child: Text(
          'SupervisorAuthPage',
          style: AppTypography.subtitle1TextStyle,
        ),
      ),
    );
  }
}
