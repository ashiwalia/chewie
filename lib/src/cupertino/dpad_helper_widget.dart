import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../chewie.dart';
import '../notifiers/index.dart';

class DPadeHelperWidget extends StatefulWidget {
  final Widget child;
  final int focusIndex;
  final Function onPressed;

  DPadeHelperWidget(
      {Key? key, required this.focusIndex, required  this.child, required this.onPressed})
      : super(key: key);

  @override
  _FocusableItemState createState() => _FocusableItemState();
}

class _FocusableItemState extends State<DPadeHelperWidget> {
  late PlayerNotifier playerNotifier;
  bool _hasFocus = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    playerNotifier = Provider.of<PlayerNotifier>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    // widget.focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {}); // Triggers a rebuild when focus changes
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              if (widget.onPressed != null && playerNotifier.optionsDialogIsShowing == false) {
                widget.onPressed!();
                return KeyEventResult.handled;
              }
              
            }
          }
          return KeyEventResult.ignored;
        },
        child: Consumer<PlayerNotifier>(
          builder: (context, homeProvider, child) {
            // print("OKAY => ${playerNotifier.focusedButtonIndex} == ${widget.focusIndex}");
            if (playerNotifier.focusedButtonIndex == widget.focusIndex) {
              focusNode.requestFocus();
              _hasFocus = true;
            } else {
              _hasFocus = false;
            }
            return IntrinsicWidth(
              child: Container(
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _hasFocus && !playerNotifier.hideStuff
                      ? Border.all(color: Colors.yellow, width: 2)
                      : null,
                ),
                child: widget.child,
              ),
            );
          },
        ));
  }
}
