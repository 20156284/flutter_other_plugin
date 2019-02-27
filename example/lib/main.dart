//import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
//import 'dart:async';
//
//import 'package:flutter/services.dart';
//import 'package:flutter_other_plugin/flutter_other_plugin.dart';
//import 'dart:ui' as ui;
//
//void main() => runApp(MyApp());
//
//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Save image to gallery',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//      ),
//      home: MyHomePage(),
//    );
//  }
//}
//
//class MyHomePage extends StatefulWidget {
//  @override
//  _MyAppState createState() => _MyAppState();
//}
//
//class _MyAppState extends State<MyHomePage> {
//  GlobalKey _globalKey = GlobalKey();
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//        appBar: AppBar(
//          title: Text("Save image to gallery"),
//        ),
//        body: Center(
//          child: Column(
//            children: <Widget>[
//              RepaintBoundary(
//                key: _globalKey,
//                child: Container(
//                  width: 200,
//                  height: 200,
//                  color: Colors.red,
//                ),
//              ),
//              Container(
//                child: RaisedButton(
//                  onPressed: _saved,
//                  child: Text("保存到相册"),
//                ),
//                width: 100,
//                height: 50,
//              )
//            ],
//          ),
//        ));
//  }
//
//  _saved() async {
//    RenderRepaintBoundary boundary =
//        _globalKey.currentContext.findRenderObject();
//    ui.Image image = await boundary.toImage();
//    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//    final result = await FlutterOtherPlugin.save(byteData.buffer.asUint8List());
//    print(result);
//  }
//}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_other_plugin/flutter_other_plugin.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LocationData _startLocation;
  LocationData _currentLocation;

  StreamSubscription<LocationData> _locationSubscription;

  FlutterOtherPlugin _location = new FlutterOtherPlugin();
  bool _permission = false;
  String error;

  bool currentWidget = true;

  Image image1;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _locationSubscription =
        _location.onLocationChanged().listen((LocationData result) {
      setState(() {
        _currentLocation = result;
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      _permission = await _location.hasPermission();
      location = await _location.getLocation();

      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //if (!mounted) return;

    setState(() {
      _startLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets;

    if (_currentLocation == null) {
      widgets = new List();
    } else {
      widgets = [
        new Image.network(
            "https://maps.googleapis.com/maps/api/staticmap?center=${_currentLocation.latitude},${_currentLocation.longitude}&zoom=18&size=640x400&key=YOUR_API_KEY")
      ];
    }

    widgets.add(new Center(
        child: new Text(_startLocation != null
            ? 'Start location: ${_startLocation.latitude} & ${_startLocation.longitude}\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
        child: new Text(_currentLocation != null
            ? 'Continuous location: ${_currentLocation.latitude} & ${_currentLocation.longitude}\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
        child: new Text(
            _permission ? 'Has permission : Yes' : "Has permission : No")));

    return new MaterialApp(
        home: new Scaffold(
            appBar: new AppBar(
              title: new Text('Location plugin example app'),
            ),
            body: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            )));
  }
}
