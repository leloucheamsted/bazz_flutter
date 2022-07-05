import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gnss_status/gnss_status.dart';
import 'package:gnss_status/gnss_status_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Permission.location.request().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GNSS Status Plugin Demo"),
      ),
      body: Center(
        child: StreamBuilder<GnssStatusModel>(builder: (context, snapshot) {
          if(snapshot.data == null) {
            return CircularProgressIndicator();
          }
          List<Map<String, dynamic>> toSend = [];
          snapshot..data.status.forEach((element) {
            toSend.add(element.toJson());
          });
          return Text(toSend.toString() ?? "");
        }, stream: GnssStatus().gnssStatusEvents,),
      ),
    );
  }
}
