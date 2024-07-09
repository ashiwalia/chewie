import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../notifiers/index.dart';

class DPadeOptionsItemWidget extends StatefulWidget {
  final Widget child;
  final int focusIndex;
  final ValueNotifier<int> currentFocusIndex;
  final Function onPressed;

  DPadeOptionsItemWidget(
      {Key? key,
      required this.focusIndex,
      required this.currentFocusIndex,
      required this.child,
      required this.onPressed})
      : super(key: key);

  @override
  _FocusableItemState createState() => _FocusableItemState();
}

class _FocusableItemState extends State<DPadeOptionsItemWidget> {
  bool _hasFocus = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
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

  void updateFocus() {
    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   if (widget.focusIndex == widget.currentFocusIndex) {
    //     _hasFocus = true;
    //   } else {
    //     _hasFocus = false;
    //   }
    //   print("HELLO => Updating UI after build");
    //   setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    print("HELLO => SETTING INDEX == ${widget.currentFocusIndex}");
    updateFocus();
    return Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              if (widget.onPressed != null) {
                widget.onPressed!();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: ValueListenableBuilder(
          builder: (context, value, child) {
            _hasFocus = widget.focusIndex == value;
            return IntrinsicWidth(
              child: Container(
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _hasFocus
                      ? Border.all(color: Colors.yellow, width: 2)
                      : null,
                ),
                child: widget.child,
              ),
            );
          },
          valueListenable: widget.currentFocusIndex,
        ));
  }
}
