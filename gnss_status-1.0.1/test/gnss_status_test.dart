import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnss_status/gnss_status.dart';

void main() {
  const MethodChannel channel = MethodChannel('gnss_status');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
