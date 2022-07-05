import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_popup/src/popup_event_actions.dart';

class PopupEvent {
  final Marker marker;
  final List<Marker> markers;
  final PopupEventActions action;

  PopupEvent.hideInList(this.markers)
      : marker = null as Marker,
        action = PopupEventActions.hideInList;

  PopupEvent.hideAny()
      : marker = null as Marker,
        markers = null as List<Marker>,
        action = PopupEventActions.hideAny;

  PopupEvent.toggle(this.marker)
      : markers = null as List<Marker>,
        action = PopupEventActions.toggle;

  PopupEvent.show(this.marker)
      : markers = null as List<Marker>,
        action = PopupEventActions.show;
}
