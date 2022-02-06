import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remove_background/remove_background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remove Background Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Remove Background Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoaded = false;
  ui.Image? image;
  ByteData? pngBytes;

  @override
  initState() {
    getUiImage();
    super.initState();
  }

  getUiImage() async {
    ByteData data = await rootBundle.load('images/test_image.jpg');
    image = await decodeImageFromList(data.buffer.asUint8List());
    await getPNG();
    setState(() {
      isLoaded = true;
    });
  }

  getPNG() async {
    pngBytes = await image?.toByteData(format: ui.ImageByteFormat.png);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isLoaded
                ? Image.memory(Uint8List.view(pngBytes!.buffer))
                : const Icon(Icons.image),
            const Text(
              'Example remove background image',
            ),
            isLoaded
                ? TextButton(
                    onPressed: () async {
                      pngBytes =
                          await cutImage(context: context, image: image!);
                      setState(() {});
                    },
                    child: const Text("Cutout Image"))
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}
