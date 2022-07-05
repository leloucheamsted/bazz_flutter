import 'dart:async';
import 'dart:io';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/media.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_repo.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart' as log;
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:video_compress/video_compress.dart';

class MediaUploadService extends GetxController {
  static MediaUploadService get to => Get.find();

  final MediaUploadRepository _repo = MediaUploadRepository();

  final Map<String, List<UploadableMedia>> allMediaByEventId = {};

  final RxDouble _avgUploadProgress$ = 0.0.obs;

  double get avgUploadProgress$ => _avgUploadProgress$.value;

  set avgUploadProgress$(double value) {
    _avgUploadProgress$(value);
  }

  final RxBool _isProcessingMedia$ = false.obs;

  bool get isProcessingMedia$ => _isProcessingMedia$.value;

  set isProcessingMedia$(bool value) {
    _isProcessingMedia$(value);
  }

  StreamSubscription? _avgProgressSub;

  @override
  void onInit() {
    _avgProgressSub = _avgUploadProgress$.listen((val) {
      if (val == 1.0) isProcessingMedia$ = false;
    });
    super.onInit();
  }

  @override
  void onClose() {
    VideoCompress.deleteAllCache();
    _avgProgressSub?.cancel();
    super.onClose();
  }

  void resetAvgProgress() {
    avgUploadProgress$ = 0.0;
    isProcessingMedia$ = false;
  }

  void addAllMedia(String id, Iterable<UploadableMedia> med) {
    if (allMediaByEventId[id] == null) {
      allMediaByEventId[id] = [];
    }
    allMediaByEventId[id]!.insertAll(0, med);
  }

  void uploadAllMediaForId(String id, {bool showError = true}) {
    //TODO: since now we have avgUploadProgress$ observable, we don't need to update 'avgUploadProgress' id,
    // but first we need to refactor media uploading UI in the EventsView
    update(['avgUploadProgress', 'button$id']);
    isProcessingMedia$ = true;
    updateAvgUploadProgress(allMediaByEventId[id]!);

    for (final media in allMediaByEventId[id]!) {
      if (media.isUploaded ||
          media.isUploading ||
          media.cancelToken.isCancelled) continue;

      if (media.compressedFilePath != null) {
        _uploadSingle(media, showError: showError);
      } else if (media.isImage) {
        media.compressedFilePath = media.path;
        _uploadSingle(media, showError: showError);
      } else {
        if (VideoCompress.isCompressing) continue;

        Subscription? subscription;

        TelloLogger().i('Compressing video...');
        //FIXME: sometimes this subscription breaks the code, need to check
        // subscription = VideoCompress.compressProgress$.subscribe((progress) {
        //   media.compressProgress(progress);
        //   Logger().log('compress progress: $progress');
        // });

        media.isCompressing(true);
        VideoCompress.compressVideo(
          media.path,
          quality: VideoQuality.MediumQuality,
        ).then((info) {
          media.isCompressing(false);
          TelloLogger().i('Compression result: ${info?.toJson()}');
          media.compressedFilePath = info!.path as String;
          subscription!.unsubscribe();

          uploadAllMediaForId(id);
        }).catchError((e, s) {
          TelloLogger().e('Video compression error: $e',
              stackTrace: s is StackTrace ? s : null);
        });
      }
    }
  }

  Future<void> _uploadSingle(UploadableMedia media,
      {bool showError = true}) async {
    try {
      if (media.compressedFilePath == null)
        throw 'media.compressedFilePath is null!';

      final isOnline = await DataConnectionChecker().isConnectedToInternet;

      if (isOnline) {
        if (media.signedUrl == null) {
          final signedUrlResponse = await _repo.getSignedUrl(
              basename(media.compressedFilePath),
              withLongLife: true);
          media
            ..signedUrl = signedUrlResponse!.signedUrl
            ..publicUrl = signedUrlResponse.publicUrl;
        }

        await _repo.uploadFile(
          signedUrl: media.signedUrl,
          file: File(media.compressedFilePath),
          mimeType: lookupMimeType(media.compressedFilePath)!,
          cancelToken: media.cancelToken,
          onSendProgress: (sent, total) {
            media.uploadProgress(sent / total);
            updateAvgUploadProgress(allMediaByEventId[media.parentEventId]!);
            TelloLogger().i(
                'Media upload progress: ${sent / total}. Avg: ${avgUploadProgress$}');
          },
        );
        media.isUploadDeferred(false);
        media.uploadComplete.complete();
      } else {
        media.deferUpload();
        updateAvgUploadProgress(allMediaByEventId[media.parentEventId]!);
        media.uploadComplete.completeError(MediaUploadError());
      }
    } on DioError catch (e, s) {
      if (e.type == DioErrorType.cancel) {
        return TelloLogger().i('Upload has been cancelled by user');
      } else {
        media.deferUpload();
        updateAvgUploadProgress(allMediaByEventId[media.parentEventId]!);
        media.uploadComplete.completeError(MediaUploadError());
        if (showError) {
          Get.showSnackbar(GetBar(
            backgroundColor: AppColors.error,
            message: '${e.error}',
            titleText: Text(
              LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle,
            ),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.brightIcon,
            ),
          ));
        }
        TelloLogger().e('error during uploading media: $e', stackTrace: s);
      }
    } finally {
      update(['avgUploadProgress', 'button${media.parentEventId}']);
    }
  }

  void cancelAllForId(String id) {
    for (final media in allMediaByEventId[id]!) {
      media.cancelToken.cancel('Upload has been cancelled');
    }
    allMediaByEventId[id] = null as List<UploadableMedia>;
    resetAvgProgress();
    VideoCompress.cancelCompression();
    update(['avgUploadProgress', 'button$id']);
    if (Get.isDialogOpen!) Get.until((_) => Get.isOverlaysClosed);
  }

  void cancelSingle(String eventId, int index) {
    allMediaByEventId[eventId]![index]
        .cancelToken
        .cancel('Upload has been cancelled');
    allMediaByEventId[eventId]!.removeAt(index);
    final allMedia = allMediaByEventId[eventId] ?? [];
    if (allMedia.isNotEmpty) {
      updateAvgUploadProgress(allMedia);
    } else {
      resetAvgProgress();
    }
    VideoCompress.cancelCompression();
    if (allMediaByEventId[eventId]!.isEmpty && Get.isDialogOpen!)
      Get.until((_) => Get.isOverlaysClosed);
    update(['avgUploadProgress', 'uploadingMediaList', 'button$eventId']);
  }

  void deleteSingle(String eventId, int index) {
    allMediaByEventId[eventId]!.removeAt(index);
    final allMedia = allMediaByEventId[eventId] ?? [];
    avgUploadProgress$ = allMedia.isNotEmpty
        ? allMedia.map((m) => m.uploadProgress()).reduce((a, b) => a + b) /
            allMedia.length
        : 0.0;
  }

  void deleteAllById(String id) {
    allMediaByEventId.remove(id);
    resetAvgProgress();
    update(['avgUploadProgress', 'button$id']);
  }

  void changeMediaParent(String oldParentId, String newParentId) {
    if (allMediaByEventId[oldParentId] == null) return;

    for (final m in allMediaByEventId[oldParentId]!) {
      m.setParentEventId(newParentId);
    }
    allMediaByEventId[newParentId] = allMediaByEventId[oldParentId]!;
    allMediaByEventId.remove(oldParentId);
  }

  void updateAvgUploadProgress(List<UploadableMedia> allMedia) {
    avgUploadProgress$ =
        allMedia.map((m) => m.uploadProgress()).reduce((a, b) => a + b) /
            allMedia.length;
  }

  ///ensure that media.compressedFilePath != null, and that's the case if you have tried
  /// calling uploadAllMediaForId() beforehand
  Future<bool> getAllLinksById(String id) async {
    TelloLogger().i('getAllLinksById() called');
    final isOnline = await DataConnectionChecker().isConnectedToInternet;
    if (isOnline) {
      try {
        await Future.wait(allMediaByEventId[id]!.map(
          (media) {
            assert(media.compressedFilePath != null);
            return _repo
                .getSignedUrl(
                  basename(media.compressedFilePath),
                  withLongLife: true,
                )
                .then((signedUrlResponse) => media
                  ..signedUrl = signedUrlResponse!.signedUrl
                  ..publicUrl = signedUrlResponse.publicUrl);
          },
        ));
        return true;
      } on DioError catch (e, s) {
        if (e is DioError && e.type == DioErrorType.cancel) {
          TelloLogger()
              .e('Getting links has been cancelled by user', stackTrace: s);
        } else {
          TelloLogger().e('getAllLinksById() error: $e', stackTrace: s);
          rethrow;
        }
        return false;
      }
    }
    return false;
  }

  void buildUploadDetailsDialog(String eventId) {
    Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: 'BarrierLabel',
      pageBuilder: (_, __, ___) {
        return Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            child: SizedBox(
              width: Get.width * 0.7,
              //TODO: calculate height dynamically
              height: Get.height * 0.3,
              child: Scaffold(
                backgroundColor: AppTheme().colors.mainBackground,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      color: AppColors.primaryAccent,
                      child: TextOneLine(
                        LocalizationService()
                            .of()
                            .uploadProgress
                            .capitalizeFirst,
                        textAlign: TextAlign.center,
                        style: AppTheme().typography.dialogTitleStyle,
                      ),
                    ),
                    GetBuilder<MediaUploadService>(
                        id: 'uploadingMediaList',
                        builder: (controller) {
                          return Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(5, 5, 0, 5),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context, index) {
                                        return Obx(() {
                                          final media =
                                              controller.allMediaByEventId[
                                                  eventId]![index];
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    TextOneLine(
                                                      basename(media.path),
                                                      style: AppTheme()
                                                          .typography
                                                          .bgText4Style,
                                                    ),
                                                    if (media.isCompressing())
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                bottom: 5),
                                                        child: Text(
                                                          '{LocalizationService().of().compressingMedia}...',
                                                          //.capitalizeFirst,
                                                          style: AppTheme()
                                                              .typography
                                                              .bgText4Style,
                                                        ),
                                                      )
                                                    else
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                bottom: 5),
                                                        child:
                                                            LinearPercentIndicator(
                                                          percent: media
                                                              .uploadProgress(),
                                                          lineHeight: 15.0,
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 8,
                                                                  right: 10),
                                                          center: Text(
                                                            '${(media.uploadProgress() * 100).truncate()}%',
                                                            style: AppTypography
                                                                .bodyText4TextStyle
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .brightText),
                                                          ),
                                                          backgroundColor: media
                                                                  .isUploadDeferred()
                                                              ? AppTheme()
                                                                  .colors
                                                                  .disabledButton
                                                                  .withOpacity(
                                                                      0.2)
                                                              : AppColors
                                                                  .primaryAccent
                                                                  .withOpacity(
                                                                      0.2),
                                                          progressColor: media
                                                                  .isUploadDeferred()
                                                              ? AppTheme()
                                                                  .colors
                                                                  .disabledButton
                                                              : AppColors
                                                                  .primaryAccent,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (media.uploadProgress() < 1)
                                                CircularIconButton(
                                                  buttonSize: 30,
                                                  onTap: () {
                                                    controller.cancelSingle(
                                                        eventId, index);
                                                  },
                                                  child: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: AppColors.error,
                                                  ),
                                                )
                                              else
                                                CircularIconButton(
                                                  buttonSize: 30,
                                                  onTap: null as VoidCallback,
                                                  child: Icon(
                                                      Icons.check_rounded,
                                                      color: media
                                                              .isUploadDeferred()
                                                          ? AppTheme()
                                                              .colors
                                                              .disabledButton
                                                          : AppColors
                                                              .primaryAccent),
                                                )
                                            ],
                                          );
                                        });
                                      },
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                              endIndent: 5, height: 5),
                                      itemCount: controller
                                          .allMediaByEventId[eventId]!.length,
                                    ),
                                  ),
                                ),
                                Obx(() {
                                  final allMedia =
                                      controller.allMediaByEventId[eventId] ??
                                          [];
                                  final avgUploadProgress = allMedia.isNotEmpty
                                      ? allMedia
                                              .map((m) => m.uploadProgress())
                                              .reduce((a, b) => a + b) /
                                          allMedia.length
                                      : 0.0;
                                  final inProgress = avgUploadProgress < 1;

                                  return PrimaryButton(
                                    height: 40,
                                    color: inProgress
                                        ? AppColors.error
                                        : AppColors.primaryAccent,
                                    onTap: () {
                                      if (inProgress) {
                                        cancelAllForId(eventId);
                                      } else {
                                        Get.until((_) => Get.isOverlaysClosed);
                                      }
                                    },
                                    icon: null as Icon,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (inProgress)
                                          const Icon(Icons.close_rounded,
                                              color: AppColors.brightIcon)
                                        else
                                          const Icon(Icons.check_rounded,
                                              color: AppColors.brightIcon),
                                        const SizedBox(width: 5),
                                        Text(
                                          inProgress ? 'Cancel All' : 'Done',
                                          style: const TextStyle(
                                            color: AppColors.brightText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 5),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UploadableMedia extends Media {
  UploadableMedia(
      {required String path, required this.parentEventId, String? thumbPath})
      : super(path: path, thumbPath: thumbPath!);

  late String parentEventId;
  late String signedUrl, publicUrl, compressedFilePath;
  final CancelToken cancelToken = CancelToken();
  final RxDouble uploadProgress = 0.0.obs;
  final RxDouble compressProgress = 0.0.obs;
  RxBool isUploadDeferred = false.obs;
  Completer uploadComplete = Completer();

  bool get isUploadCanceled => cancelToken.isCancelled;

  bool get isUploaded => uploadProgress() == 1;

  bool get isUploading => uploadProgress() > 0 && uploadProgress() < 1;

  // bool get isCompressing => compressProgress() > 0 && compressProgress() < 1;
  RxBool isCompressing = false.obs;

  void setParentEventId(String newParentEventId) {
    parentEventId = newParentEventId;
  }

  void deferUpload() {
    isUploadDeferred(true);
    uploadProgress(1);
  }

  Map<String, dynamic> toMap() {
    return {
      'parentEventId': parentEventId,
      'path': path,
      'thumbPath': thumbPath,
      'compressedFilePath': compressedFilePath,
      'signedUrl': signedUrl,
      'publicUrl': publicUrl,
      'isUploadDeferred': isUploadDeferred(),
    };
  }

  factory UploadableMedia.fromMap(Map<String, dynamic> map) {
    return UploadableMedia(
      path: map['path'] as String,
      parentEventId: map['parentEventId'] as String,
      thumbPath: map['thumbPath'] as String,
    )
      ..compressedFilePath = map['compressedFilePath'] as String
      ..signedUrl = map['signedUrl'] as String
      ..publicUrl = map['publicUrl'] as String
      ..isUploadDeferred = (map['isUploadDeferred'] as bool).obs;
  }

  UploadableMedia copy() {
    return UploadableMedia(
        path: path, parentEventId: parentEventId, thumbPath: thumbPath)
      ..signedUrl = signedUrl
      ..signedUrl = signedUrl
      ..publicUrl = publicUrl
      ..compressedFilePath = compressedFilePath
      ..uploadProgress.value = uploadProgress.value
      ..compressProgress.value = compressProgress.value
      ..isUploadDeferred.value = isUploadDeferred.value
      ..isCompressing.value = isCompressing.value
      ..uploadComplete = uploadComplete
      ..isUploadDeferred.value = isUploadDeferred.value;
  }
}

class MediaUploadError {}
