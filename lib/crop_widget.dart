import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Uint8List? byteList;
ui.Image? image;

bool flipImage = false;
ui.PictureRecorder recorder = ui.PictureRecorder();
Canvas canvas = Canvas(recorder);
var brushSize = 15.0;
bool themeState = false;

enum WidgetMarker { none, flip, auto, manual }

class Cutout extends StatefulWidget {
  final ui.Image image;

  const Cutout({Key? key, required this.image}) : super(key: key);
  static const String id = 'Cutout';

  @override
  _CutoutState createState() => _CutoutState();
}

class _CutoutState extends State<Cutout> {
  WidgetMarker selectedWidgetMarker = WidgetMarker.manual;

  @override
  void initState() {
    loadImage();
    super.initState();
  }

  Future loadImage() async {
    var theme = true;
    var byte = await widget.image.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      image = widget.image;
      byteList = byte!.buffer.asUint8List();
      themeState = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Scaffold(
        body: Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: MediaQuery.of(context).size.width * 0.01,
              right: MediaQuery.of(context).size.width * 0.01),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                    splashRadius: 20.0,
                  ),
                  IconButton(
                    onPressed: () async {
                      ByteData? pngBytes;
                      if (recorder.isRecording) {
                        ui.Picture picture = recorder.endRecording();
                        ui.Image imageEx =
                            await picture.toImage(image!.width, image!.height);

                        pngBytes = await imageEx.toByteData(
                            format: ui.ImageByteFormat.png);
                      }
                      Navigator.pop(context, pngBytes);
                    },
                    icon: const Icon(Icons.check),
                    splashRadius: 20.0,
                  ),
                ],
              ),
              Container(
                // margin: const EdgeInsets.all(30.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Theme.of(context).primaryColor)),
                child: FittedBox(
                  child: SizedBox(
                    height: image!.height.toDouble(),
                    width: image!.width.toDouble(),
                    //child: AutomaticBGRemoval(),
                    child: getCustomWidget(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedWidgetMarker = WidgetMarker.manual;
                      });
                    },
                    icon: const Icon(Icons.phonelink_erase_rounded),
                    color: selectedWidgetMarker == WidgetMarker.manual
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  IconButton(
                      onPressed: () {
                        selectedWidgetMarker = WidgetMarker.none;
                      },
                      icon: const Icon(Icons.undo)),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget getCustomWidget() {
    switch (selectedWidgetMarker) {
      case WidgetMarker.manual:
        return const ManualRemoval();
      default:
        {
          return Image.memory(byteList!);
        }
    }
  }
}

class ManualRemoval extends StatefulWidget {
  const ManualRemoval({Key? key}) : super(key: key);

  @override
  _ManualRemovalState createState() => _ManualRemovalState();
}

class _ManualRemovalState extends State<ManualRemoval> {
  GlobalKey globalKey = GlobalKey();

  var paint = Paint(),
      paint1 = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0;

  @override
  void initState() {
    super.initState();
    recorder = ui.PictureRecorder();
    loadImage();

    paint.blendMode = BlendMode.clear;
    paint.color = Colors.transparent;
    paint.strokeWidth = 20.0;
  }

  loadImage() async {
    canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0.0, 0.0),
            Offset(image!.width.toDouble(), image!.height.toDouble())));
    canvas.drawImage(image!, Offset.zero, paint1);

    setState(() => image = image);
  }

  List<Offset> points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    Sketcher sketcher = Sketcher(points, image, context);
    Container sketchArea = Container();
    if (image != null) {
      sketchArea = Container(
        //margin: EdgeInsets.all(1.0),
        alignment: Alignment.topLeft,
        height: image!.height.toDouble(),
        width: image!.width.toDouble(),
        child: CustomPaint(
          size: Size(image!.width.toDouble(), image!.width.toDouble()),
          painter: sketcher,
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          Offset point = details.localPosition;
          if ((point.dy > 0 &&
              point.dx > 0 &&
              point.dx < image!.width &&
              point.dy < image!.height)) {
            canvas.drawCircle(point, 20.00, paint);
            points = List.from(points)..add(point);
          }
          // point = point.translate(0.0, -(AppBar().preferredSize.height));
        });
      },
      onPanEnd: (DragEndDetails details) {
        // points.add(null);
      },
      child: sketchArea,
    );
  }
}

class Sketcher extends CustomPainter {
  final ui.Image? image;
  final BuildContext sketcherContext;
  final List<Offset> points;
  Size? lastSize;

  Sketcher(this.points, this.image, this.sketcherContext);

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.points != points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    lastSize = size;
    Paint paint1 = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    canvas.drawImage(image!, Offset.zero, paint1);
    Paint paint = Paint();
    paint.blendMode = BlendMode.src;
    paint.color = Theme.of(sketcherContext).scaffoldBackgroundColor;
    paint.strokeWidth = 20.0;

    for (int i = 0; i < points.length - 1; i++) {
      // canvas.drawLine(points[i], points[i + 1], paint);
      canvas.drawCircle(points[i], brushSize, paint);
    }
  }
}
