import 'dart:io';

import 'package:align_positioned/align_positioned.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
import 'package:bazz_flutter/modules/shift_activities/models/no_qr.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({Key? key}) : super(key: key);

  @override
  _QrScannerState createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool _isFlashOn = false;

  @override
  void reassemble() {
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
    super.reassemble();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> toggleFlash() async {
    await controller!.toggleFlash();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: QRView(
                key: qrKey,
                overlay: QrScannerOverlayShape(
                    borderColor: AppColors.qrScannerRect,
                    cutOutSize: Get.width * 0.3),
                onQRViewCreated: (qrController) {
                  controller = qrController;
                  controller!.scannedDataStream.listen((scanData) async {
                    controller!.dispose();
                    Get.back<Barcode>(result: scanData, closeOverlays: true);
                  });
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                highlightColor: Colors.transparent,
                icon: const Icon(Icons.arrow_back, color: AppColors.brightText),
                onPressed: () {
                  Get.back(closeOverlays: true);
                },
              ),
            ),
            AlignPositioned(
              alignment: Alignment.bottomCenter,
              child: CircularIconButton(
                onTap: toggleFlash,
                buttonSize: 70,
                child: Icon(
                  _isFlashOn ? Icons.flash_off : Icons.flash_on,
                  size: 30,
                  color: AppColors.brightIcon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
