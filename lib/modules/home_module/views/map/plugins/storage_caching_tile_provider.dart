import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/tile_layer.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import './tile_storage_caching_manager.dart';

export './tile_storage_caching_manager.dart';

///Provider that persist loaded raster tiles inside local sqlite db
/// [cachedValidDuration] - valid time period since [DateTime.now]
/// which determines the need for a request for remote tile server. Default value
/// is one day, that means - all cached tiles today and day before don't need rewriting.
class StorageCachingTileProvider extends TileProvider {
  static final kMaxPreloadTileAreaCount = 10000;
  final Duration cachedValidDuration;
  StorageCachingTileProvider(
      {this.cachedValidDuration = const Duration(days: 1)});
  static TextStyle textStyle = const TextStyle(
    color: Colors.red,
    fontSize: 8,
  );

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final tileUrl = getTileUrl(coords, options);
    //Logger().log("ImageProvider getImage ${coords.toString()} ,, $tileUrl");
    return CachedTileImageProvider(tileUrl,
        Coords<int>(coords.x.toInt(), coords.y.toInt())..z = coords.z.toInt());
  }

  final Crs crs = Epsg3857();
  final CustomPoint tileSize = CustomPoint(256, 256);

  /// Caching tile area by provided [bounds], zoom edges and [options].
  /// The maximum number of tiles to load is [kMaxPreloadTileAreaCount].
  /// To check tiles number before calling this method, use
  /// [approximateTileAmount].
  /// Return [Tuple3] with number of downloaded tiles as [Tuple3.item1],
  /// number of errored tiles as [Tuple3.item2], and number of total tiles that need to be downloaded as [Tuple3.item3]
  Stream<Tuple3<int, int, int>> loadTiles(
      LatLngBounds bounds, int minZoom, int maxZoom, TileLayerOptions options,
      {Function(dynamic)? errorHandler}) async* {
    final tilesRange = approximateTileRange(
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileSize: CustomPoint(options.tileSize, options.tileSize));
    assert(tilesRange.length <= kMaxPreloadTileAreaCount,
        '${tilesRange.length} exceeds maximum number of pre-cacheable tiles');
    var errorsCount = 0;
    for (var i = 0; i < tilesRange.length; i++) {
      try {
        final cord = tilesRange[i];
        final url = getTileUrl(cord, options);
        // get network tile
        final bytes = (await http.get(Uri.parse(url))).bodyBytes;
        // save tile to cache
        TileStorageCachingManager.saveTile(bytes, cord);
      } catch (e) {
        errorsCount++;
        if (errorHandler != null) errorHandler(e);
      }
      yield Tuple3(i + 1, errorsCount, tilesRange.length);
    }
  }

  ///Get approximate tile amount from bounds and zoom edges.
  ///[crs] and [tileSize] is optional.
  static Future<int> approximateTileAmount({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    crs,
    tileSize,
  }) async {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    var amount = 0;
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      final a = sePoint.x - nwPoint.x + 1;
      final b = sePoint.y - nwPoint.y + 1;
      amount += a.toInt() * b.toInt() as int;
    }
    return amount;
  }

  ///Get tileRange from bounds and zoom edges.
  ///[crs] and [tileSize] is optional.
  static List<Coords> approximateTileRange(
      {required LatLngBounds bounds,
      required int minZoom,
      required int maxZoom,
      crs,
      tileSize}) {
    assert(minZoom <= maxZoom, 'minZoom > maxZoom');
    final cords = <Coords>[];
    for (var zoomLevel in List<int>.generate(
        maxZoom - minZoom + 1, (index) => index + minZoom)) {
      final nwPoint = crs
          .latLngToPoint(bounds.northWest, zoomLevel.toDouble())
          .unscaleBy(tileSize!)
          .floor();
      final sePoint = crs
              .latLngToPoint(bounds.southEast, zoomLevel.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      for (var x = nwPoint.x; x <= sePoint.x; x++) {
        for (var y = nwPoint.y; y <= sePoint.y; y++) {
          cords.add(Coords(x, y)..z = zoomLevel);
        }
      }
    }
    return cords;
  }
}

class CachedTileImageProvider extends ImageProvider<Coords<int>> {
  final Function(dynamic)? netWorkErrorHandler;
  final String url;
  final Coords<int> coords;
  final Duration cacheValidDuration;
  final Paint boxPaint = Paint();
  CachedTileImageProvider(this.url, this.coords,
      {this.cacheValidDuration = const Duration(days: 1),
      this.netWorkErrorHandler});

  @override
  ImageStreamCompleter load(Coords<int> key, decode) =>
      MultiFrameImageStreamCompleter(
          codec: _loadAsync(),
          scale: 1,
          informationCollector: () sync* {
            yield DiagnosticsProperty<ImageProvider>('Image provider', this);
            yield DiagnosticsProperty<Coords>('Image key', key);
          });

  @override
  Future<Coords<int>> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(coords);

  Future<Codec> _loadAsync() async {
    final localBytes = await TileStorageCachingManager.getTile(coords);

    var bytes = localBytes.item1;
    if ((DateTime.now().millisecondsSinceEpoch -
            (localBytes.item2.millisecondsSinceEpoch)) >
        cacheValidDuration.inMilliseconds) {
      try {
        // get network tile
        bytes = (await http.get(Uri.parse(url))).bodyBytes;
        // save tile to cache
        TileStorageCachingManager.saveTile(bytes, coords);
      } catch (e) {
        if (netWorkErrorHandler != null) netWorkErrorHandler!(e);
      }
    }
    bytes = await createNoTileImage();

    final result = await PaintingBinding.instance.instantiateImageCodec(bytes);
    return result;
  }

  Future<Uint8List> createNoTileImage() async {
    TelloLogger().i("createNoTileImage() ====> ");
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    boxPaint.isAntiAlias = true;
    boxPaint.color = Colors.blue;
    boxPaint.strokeWidth = 1.0;
    boxPaint.style = PaintingStyle.stroke;
    final TextSpan textSpan = TextSpan(
      text: 'NO TILE',
      style: StorageCachingTileProvider.textStyle,
    );
    const int width = 256;
    const int height = 256;
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0.0,
      maxWidth: width.toDouble(),
    );

    const Offset offset = Offset(0, 0);
    textPainter.paint(canvas, offset);
    canvas.drawRect(
        Rect.fromLTRB(0, 0, width.toDouble(), width.toDouble()), boxPaint);
    final ui.Picture picture = recorder.endRecording();
    final Uint8List byteData = await picture
        .toImage(width, height)
        .then((ui.Image image) =>
            image.toByteData(format: ui.ImageByteFormat.png))
        .then((ByteData? byteData) => byteData!.buffer.asUint8List());

    return byteData;
  }
}
