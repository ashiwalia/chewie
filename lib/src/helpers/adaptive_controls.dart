import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class AdaptiveControls extends StatelessWidget {
  const AdaptiveControls({
    required this.chewieController,
    super.key,
  });
  final ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    if (chewieController.isTv) {
      return const CupertinoControls(
        backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
        iconColor: Color.fromARGB(255, 200, 200, 200),
      );
    }
    return const MaterialControls();
  }
}
