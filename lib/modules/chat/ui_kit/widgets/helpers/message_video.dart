import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_footer.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/path_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// A default Widget that can be used to show a video preview.
/// One would play the video upon clicking the item.
/// This is more an example to give you an idea how to structure your own Widget,
/// since too many aspects would require to be customized, for instance
/// implementing your own image loader, padding, constraints, footer etc.
class ChatMessageVideo extends StatefulWidget {
  final int index;

  final ChatMessage message;

  final MessagePosition messagePosition;

  final MessageFlow messageFlow;

  const ChatMessageVideo(
      this.index, this.message, this.messagePosition, this.messageFlow,
      {Key? key})
      : super(key: key);

  @override
  _ChatMessageVideoState createState() => _ChatMessageVideoState();
}

class _ThumbnailData {
  bool isNetwork = false;
  String? path;
  bool hasData = false;
}

class _ChatMessageVideoState extends State<ChatMessageVideo> {
  Future<_ThumbnailData>? _videoThumbnail;

  @override
  void initState() {
    final directory =
        StoragePaths().getDirectoryByMessageType(widget.message.messageType);
    final File filePath = File('$directory/${widget.message.fileName}');
    TelloLogger().i("Loading _videoThumbnail ${filePath.path}");
    // _videoData = getVideoInfo(File(widget.message.attachmentUrl));
    _videoThumbnail = getVideoThumbnail(filePath);
    super.initState();
  }

  Future<_ThumbnailData> getVideoThumbnail(File filePath) async {
    final _ThumbnailData thumbnailData = _ThumbnailData();
    try {
      thumbnailData.hasData = true;
      final thumbnailPath = (await getExternalStorageDirectory())!.path;
      final _file = File(widget.message.attachmentUrl);
      final filename = basename(_file.path);
      final extenion = extension(_file.path);
      final newfile = filename.replaceAll(extenion, ".png");
      final previewImageAttachment =
          widget.message.attachmentUrl.replaceAll(extenion, ".png");

      final response = await http.head(previewImageAttachment as Uri);

      if (response.statusCode == 200) {
        thumbnailData.isNetwork = true;
        thumbnailData.path = previewImageAttachment;
        return thumbnailData;
      }

      final thumbnailCachedFile = File("$thumbnailPath/$newfile");
      final exists = thumbnailCachedFile.existsSync();

      if (exists) {
        thumbnailData.isNetwork = false;
        thumbnailData.path = thumbnailCachedFile.path;
        return thumbnailData;
      }

      final thumbnailFilePath = await VideoThumbnail.thumbnailFile(
        video: filePath.existsSync()
            ? filePath.path
            : widget.message.attachmentUrl,
        thumbnailPath: (await getExternalStorageDirectory())!.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 300,
        maxHeight: 240,
        quality: 10,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        thumbnailData.hasData = false;
        return "no data";
      });
      TelloLogger().i(
          "thumbnailFilePath====> $thumbnailFilePath ,,, ${(await getExternalStorageDirectory())!.path}");
      thumbnailData.isNetwork = false;
      thumbnailData.path = thumbnailFilePath;
      return thumbnailData;
    } catch (e, s) {
      TelloLogger().e("Loading _videoThumbnail err ===> $e", stackTrace: s);
      thumbnailData.hasData = false;
      return thumbnailData;
    }
  }

  /// Retrieve video metaData
  // Future<VideoData> getVideoInfo(File file) {
  //   final videoInfo = FlutterVideoInfo();
  //   return videoInfo.getVideoInfo(file.path);
  // }

  @override
  Widget build(BuildContext context) {
    const double maxSizeHeight = 150;
    const double maxSizeWidth = 150;
    // final Widget _footer = Padding(
    //     padding: EdgeInsets.all(8),
    //     child: Row(
    //       mainAxisSize: MainAxisSize.min,
    //       crossAxisAlignment: CrossAxisAlignment.end,
    //       children: [
    //         Icon(Icons.videocam),
    //         FutureBuilder(
    //             future: _videoData,
    //             builder: (BuildContext context, snapshot) {
    //               if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
    //                 final VideoData data = snapshot.data as VideoData;
    //                 return Padding(
    //                     padding: EdgeInsets.symmetric(horizontal: 8),
    //                     child: Text(Duration(milliseconds: data.duration.toInt()).verboseDuration));
    //               }
    //               return Container();
    //             }),
    //         Spacer(),
    //         MessageFooter(widget.message)
    //       ],
    //     ));

    return SizedBox(
        height: maxSizeHeight,
        width: maxSizeWidth,
        child: FutureBuilder(
            future: _videoThumbnail,
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null) {
                return MessageContainer(
                    constraints: const BoxConstraints(
                        maxWidth: maxSizeWidth, maxHeight: maxSizeHeight),
                    padding: EdgeInsets.zero,
                    decoration: messageDecoration(context,
                        messagePosition: widget.messagePosition,
                        color: Colors.transparent,
                        messageFlow: widget.messageFlow),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.message.isDownloaded) {
                          ChatController.to
                              .playVideo(widget.message.attachmentFile);
                        } else if (widget.message.isDownloading.isFalse) {
                          ChatController.to.downloadFile(widget.message);
                        } else {
                          ChatController.to.cancelDownloading(widget.message);
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if ((snapshot.data as _ThumbnailData).hasData &&
                              !(snapshot.data as _ThumbnailData).isNetwork)
                            Image.file(File((snapshot.data as String)),
                                fit: BoxFit.cover,
                                width: maxSizeWidth,
                                height: maxSizeHeight)
                          else if ((snapshot.data as _ThumbnailData).hasData &&
                              (snapshot.data as _ThumbnailData).isNetwork)
                            Image.network((snapshot.data as String),
                                fit: BoxFit.cover,
                                width: maxSizeWidth,
                                height: maxSizeHeight)
                          else
                            const Icon(
                              Icons.not_interested,
                              color: AppColors.brightText,
                              size: maxSizeWidth,
                            ),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: MessageFooter(widget.message),
                          ),
                          Obx(() {
                            return widget.message.isCompressing()
                                ? const Positioned(
                                    bottom: 55,
                                    child: Text(
                                      "Compressing...",
                                      style: AppTypography.bodyText2TextStyle,
                                    ))
                                : Container();
                          }),
                          if ((snapshot.data as _ThumbnailData).hasData)
                            Obx(() {
                              return ClipOval(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: Colors.black38,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (widget.message.downloadProgress() <
                                          100)
                                        SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                        Color>(
                                                    AppColors.brightText),
                                            value: widget.message
                                                    .downloadProgress() /
                                                100,
                                          ),
                                        ),
                                      Icon(
                                        widget.message.isDownloading()
                                            ? Icons.close_rounded
                                            : widget.message.isDownloaded
                                                ? Icons.play_arrow_rounded
                                                : Icons.arrow_downward_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ));
              }

              return MessageContainer(
                constraints: const BoxConstraints(
                    maxWidth: maxSizeHeight, maxHeight: maxSizeHeight),
                padding: EdgeInsets.zero,
                decoration: messageDecoration(context,
                    messagePosition: widget.messagePosition,
                    color: Colors.black12,
                    messageFlow: widget.messageFlow),
                child: Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.loadingIndicator,
                    size: 35,
                  ),
                ),
              );
            }));
  }
}
