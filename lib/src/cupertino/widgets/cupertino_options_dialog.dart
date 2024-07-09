import 'package:chewie/src/models/option_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../notifiers/player_notifier.dart';
import '../focusable_options_item.dart';

class CupertinoOptionsDialog extends StatefulWidget {
  const CupertinoOptionsDialog(
      {super.key, required this.options, this.cancelButtonText, this.keyEvent});

  final List<OptionItem> options;
  final String? cancelButtonText;
  final ValueNotifier<KeyEvent?>? keyEvent;

  @override
  // ignore: library_private_types_in_public_api
  _CupertinoOptionsDialogState createState() => _CupertinoOptionsDialogState();
}

class _CupertinoOptionsDialogState extends State<CupertinoOptionsDialog> {
  ValueNotifier<int> currentFocusIndex = ValueNotifier<int>(0);
  late List<OptionItem> _options;
  int maxFocusIndex = 0;

  @override
  void initState() {
    super.initState();
    _options = widget.options;

    // append cancel button to the options
    _options.add(OptionItem(
      title: widget.cancelButtonText ?? 'Cancel',
      onTap: () => Navigator.pop(context),
      iconData: Icons.cancel_outlined,
    ));

    maxFocusIndex = widget.options.length - 1;

    widget.keyEvent?.addListener(onEvent);
  }

  void onEvent() {
    _handleKeyEvent(
        widget.keyEvent!.value as KeyEvent, currentFocusIndex.value);
  }

  @override
  void dispose() {
    widget.keyEvent?.removeListener(onEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CupertinoActionSheet(
      actions: getOptionsItem(),
    ));
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int focusIndex) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    print("KKK 2 = > ${focusIndex}");

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      naviagte(NaviationType.FORWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      naviagte(NaviationType.BACKWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      naviagte(NaviationType.BACKWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      naviagte(NaviationType.FORWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.options[currentFocusIndex.value].onTap!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  List<Widget> getOptionsItem() {
    List<Widget> items = [];

    for (var i = 0; i < widget.options.length; i++) {
      items.add(
        DPadeOptionsItemWidget(
          focusIndex: i,
          currentFocusIndex: currentFocusIndex,
          onPressed: () {},
          child: CupertinoActionSheetAction(
            onPressed: () => () {
              print("OKAY => TAPPED");
            },
            child: Text(widget.options[i].title),
            isDestructiveAction: widget.options[i].title == 'Cancel',
          ),
        ),
      );
    }

    return items;

    // return widget.options.mapInde((option) {
    //   return DPadeOptionsItemWidget(
    //     focusIndex: focusedItemIndex,
    //     currentFocusIndex: currentFocusIndex,
    //     onPressed: () {
    //       option.onTap!();
    //     },
    //     child: CupertinoActionSheetAction(
    //       onPressed: () => option.onTap!(),
    //       child: Text(option.title),
    //     ),
    //   );
    // }).toList();
  }

  int getNextFocusIndex(NaviationType type) {
    int currentFocusIndexValue = currentFocusIndex.value;

    if (type == NaviationType.FORWARD) {
      if (currentFocusIndexValue == maxFocusIndex) {
        return 0;
      }

      if (currentFocusIndexValue < maxFocusIndex) {
        return currentFocusIndexValue + 1;
      }
    } else {
      if (currentFocusIndexValue == 0) {
        return maxFocusIndex;
      }
      return currentFocusIndexValue - 1;
    }

    return currentFocusIndexValue;
  }

  void naviagte(NaviationType type) {
    currentFocusIndex.value = getNextFocusIndex(type);
    print("HELLO => NAVIGATING TO ${currentFocusIndex.value}");
  }
}
