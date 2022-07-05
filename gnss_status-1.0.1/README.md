# gnss_status
A package that allows you to easily fetch the GNSSStatus via inbuilt streams.

### Example: Fetch GNSSStatusModel

        StreamBuilder<GnssStatusModel>(
            builder: (context, snapshot) {
                if(snapshot.data == null) {
                    return CircularProgressIndicator();
                }
                List<Map<String, dynamic>> toSend = [];
                snapshot..data.status.forEach((element) {
                    toSend.add(element.toJson());
                });
                 return Text(toSend.toString() ?? "");
            }, 
            stream: GnssStatus().gnssStatusEvents,
        ),
