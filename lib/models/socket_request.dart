import 'dart:async';

class SocketRequest {
  Map<String, dynamic> payload;
  Completer completer = Completer();

  SocketRequest(this.payload);
}