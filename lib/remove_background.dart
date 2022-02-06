library remove_background;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'crop_widget.dart';

cutImage({required BuildContext context, required ui.Image image}) async {
  var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cutout(image: image),
      ));
  return result;
}
