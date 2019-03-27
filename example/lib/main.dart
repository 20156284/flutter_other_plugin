import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_other_plugin/flutter_other_plugin.dart';
import 'package:path_provider/path_provider.dart';

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
  Map<String, File> loadedFiles = {};
  String localFilePath;

  StreamSubscription<LocationData> _locationSubscription;

  FlutterOtherPlugin _flutterOtherPlugin = new FlutterOtherPlugin();
  bool _permission = false;
  bool _save = false;
  String error;

  bool currentWidget = true;

  Image image1;

  GlobalKey _globalKey;

  @override
  void initState() {
    super.initState();

    _loadFile();

    initPlatformState();

    _locationSubscription =
        _flutterOtherPlugin.onLocationChanged().listen((LocationData result) {
      setState(() {
        _currentLocation = result;
      });
    });
  }

  Future<ByteData> _fetchAsset(String fileName) async {
    return await rootBundle.load('assets/$fileName');
  }

  Future<File> fetchToMemory(String fileName) async {
    final file = new File(
        '${(await getApplicationDocumentsDirectory()).path}/$fileName');
    await file.create(recursive: true);
    return await file
        .writeAsBytes((await _fetchAsset(fileName)).buffer.asUint8List());
  }

  Future<File> load(String fileName) async {
    if (!loadedFiles.containsKey(fileName)) {
      loadedFiles[fileName] = await fetchToMemory(fileName);
    }
    return loadedFiles[fileName];
  }

  Future _loadFile() async {
    File file = await fetchToMemory("msgSound.mp3");
    setState(() {
      localFilePath = file.path.toString();
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      _permission = await _flutterOtherPlugin.hasPermission();
      location = await _flutterOtherPlugin.getLocation();

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

  _saved() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    _save = await FlutterOtherPlugin.save(byteData.buffer.asUint8List());
    print(_save);
  }

  _playBell() async {
    FlutterOtherPlugin.playBell(localFilePath);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = new List();
    _globalKey = GlobalKey();

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

    widgets.add(new RepaintBoundary(
      key: _globalKey,
      child: Container(
        width: 200,
        height: 200,
        color: Colors.red,
      ),
    ));

    widgets.add(new Container(
      child: RaisedButton(
        onPressed: _saved,
        child: Text("保存到相册"),
      ),
      width: 100,
      height: 50,
    ));

    widgets.add(new Container(
      child: RaisedButton(
        onPressed: _playBell,
        child: Text("播放铃声"),
      ),
      width: 100,
      height: 50,
    ));

    return new MaterialApp(
        home: new Scaffold(
            appBar: new AppBar(
              title: new Text('Location plugin example app'),
            ),
            body: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            )));
  }
}
