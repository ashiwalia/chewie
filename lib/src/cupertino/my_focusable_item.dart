import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/index.dart';

class MyFocusableItem extends StatefulWidget {
  final Widget child;
  final int focusIndex;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyHandler;
  final bool isHomePage;

  MyFocusableItem({
    Key? key,
    required this.focusIndex,
    required this.child,
    this.onKeyHandler,
    this.isHomePage = true,
  }) : super(key: key);

  @override
  _FocusableItemState createState() => _FocusableItemState();
}

class _FocusableItemState extends State<MyFocusableItem> {
  final focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {}); // Triggers a rebuild when focus changes
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        print("HELLO => FOCUS == ${hasFocus} ${widget.focusIndex}");
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      onKeyEvent: widget.onKeyHandler != null
          ? (node, event) => widget.onKeyHandler!(node, event)
          : null,
      child: Container(
        child: widget.child,
      ),
    );
  }
}
