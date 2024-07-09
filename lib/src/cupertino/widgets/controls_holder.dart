//controls holder statful widget
import 'package:chewie/src/cupertino/widgets/cupertino_options_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../chewie.dart';

class ControlsHolder extends StatefulWidget {
  final List<OptionItem> options;

  ControlsHolder({
    Key? key,
    required this.options,
  }) : super(key: key);

  @override
  _ControlsHolderState createState() => _ControlsHolderState();
}

class _ControlsHolderState extends State<ControlsHolder> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      showControlsModelSheet();
    });
  }

  //showing the controls modelsheet
  Future<void> showControlsModelSheet() async {
    await showCupertinoModalPopup<OptionItem>(
      context: context,
      semanticsDismissible: true,
      builder: (context) => CupertinoOptionsDialog(
        options: widget.options,
        cancelButtonText: "Cancel",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(),
    );
  }
}
