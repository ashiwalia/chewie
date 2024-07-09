import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/cupertino/cupertino_progress_bar.dart';
import 'package:chewie/src/cupertino/widgets/cupertino_options_dialog.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'dpad_helper_widget.dart';
import 'my_focusable_item.dart';
import 'widgets/controls_holder.dart';

const String KEY_UP = 'Arrow Up';
const String KEY_DOWN = 'Arrow Down';
const String KEY_LEFT = 'Arrow Left';
const String KEY_RIGHT = 'Arrow Right';
const String KEY_CENTER = 'Select';
const String KEY_CENTER_KEYBOARD = 'Select';


class CupertinoControls extends StatefulWidget {
  const CupertinoControls({
    required this.backgroundColor,
    required this.iconColor,
    this.showPlayButton = true,
    this.showSeekButton = true,
    Key? key,
  }) : super(key: key);

  final Color backgroundColor;
  final Color iconColor;
  final bool showPlayButton;
  final bool showSeekButton;

  @override
  State<StatefulWidget> createState() {
    return _CupertinoControlsState();
  }
}

class _CupertinoControlsState extends State<CupertinoControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _videoPlayerValue;
  double? _latestVolume;
  Timer? _hideTimer;
  final marginSize = 5.0;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
  bool _dragging = false;
  Duration? _subtitlesPosition;
  bool _subtitleOn = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;
  double selectedSpeed = 1.0;
  late VideoPlayerController controller;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder!(
              context,
              chewieController.videoPlayerController.value.errorDescription!,
            )
          : const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return MyFocusableItem(
      focusIndex: -1,
      onKeyHandler: (FocusNode node, KeyEvent event) {
        print("OKAY => CupertinoControls onKeyHandler");
        return _handleKeyEvent(event, notifier.focusedButtonIndex, node);
      },
      child: Stack(
        children: [
          if (_displayBufferingIndicator)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            _buildHitArea(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildTopBar(
                backgroundColor,
                iconColor,
                barHeight,
                buttonPadding,
              ),
              const Spacer(),
              if (_subtitleOn)
                Transform.translate(
                  offset: Offset(
                    0.0,
                    notifier.hideStuff ? barHeight * 0.8 : 0.0,
                  ),
                  child: _buildSubtitles(chewieController.subtitle!),
                ),
              _buildBottomBar(backgroundColor, iconColor, barHeight),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildOptionsButton(
    Color iconColor,
    double barHeight,
  ) {
    final options = <OptionItem>[];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }

    return DPadeHelperWidget(
      onPressed: () async {
        notifier.hideStuff = true;
        _hideTimer?.cancel();
        controller.pause();
        notifier.setOptionsDialogIsShowing(true);

        if (chewieController.optionsBuilder != null) {
          await chewieController.optionsBuilder!(context, options);
        } else {
          await showCupertinoModalPopup<OptionItem>(
            context: context,
            semanticsDismissible: true,
            useRootNavigator: chewieController.useRootNavigator,
            builder: (context) => CupertinoOptionsDialog(
              options: options,
              cancelButtonText:
                  chewieController.optionsTranslation?.cancelButtonText,
                  keyEvent: askFocus2,
            ),
          );
          if (_videoPlayerValue.isPlaying) {
            _startHideTimer();
          }
        }
        notifier.setOptionsDialogIsShowing(false);
      },
      focusIndex: 7,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 4.0, right: 8.0),
        margin: const EdgeInsets.only(right: 6.0),
        child: Icon(
          Icons.more_vert,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSubtitles(Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    if (_subtitlesPosition == null) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition!);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: marginSize, right: marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    return SafeArea(
      bottom: chewieController.isFullScreen,
      minimum: chewieController.controlsSafeAreaMinimum,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(marginSize),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 10.0,
                sigmaY: 10.0,
              ),
              child: Container(
                height: barHeight,
                color: backgroundColor,
                child: chewieController.isLive
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildPlayPause(controller, iconColor, barHeight),
                          _buildLive(iconColor),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          _buildSkipBack(iconColor, barHeight),
                          _buildPlayPause(controller, iconColor, barHeight),
                          _buildSkipForward(iconColor, barHeight),
                          _buildPosition(iconColor),
                          _buildProgressBar(),
                          _buildRemaining(iconColor),
                          _buildSubtitleToggle(iconColor, barHeight),
                          // if (chewieController.allowPlaybackSpeedChanging)
                          //   _buildSpeedButton(controller, iconColor, barHeight),
                          if (chewieController.additionalOptions != null &&
                              chewieController
                                  .additionalOptions!(context).isNotEmpty)
                            _buildOptionsButton(iconColor, barHeight),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: DPadeHelperWidget(
        focusIndex: 0,
        onPressed: _onExpandCollapse,
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0),
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                color: backgroundColor,
                child: Center(
                  child: Icon(
                    chewieController.isFullScreen
                        ? CupertinoIcons.arrow_down_right_arrow_up_left
                        : CupertinoIcons.arrow_up_left_arrow_down_right,
                    color: iconColor,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished =
        _videoPlayerValue.position >= _videoPlayerValue.duration;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return Center(
        child: DPadeHelperWidget(
      focusIndex: 2,
      onPressed: _playPause,
      child: CenterPlayButton(
        backgroundColor: widget.backgroundColor,
        iconColor: widget.iconColor,
        isFinished: isFinished,
        isPlaying: controller.value.isPlaying,
        show: showPlayButton,
        onPressed: _playPause,
      ),
    ));
  }
ValueNotifier<KeyEvent?> askFocus2 = ValueNotifier<KeyEvent?>(null);

  KeyEventResult _handleKeyEvent(
      KeyEvent event, int focusIndex, FocusNode node) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }


    //pass key event to options dialog
    if (notifier.optionsDialogIsShowing) {
      // for (var child in node.children) {
      //   if (child.onKeyEvent != null) {
      //     // Propagate the event to the child
      //     KeyEventResult childResult = child.onKeyEvent!(child, event);
      //     if (childResult == KeyEventResult.handled) {
      //       // If the child handles the event, stop propagating
      //       return KeyEventResult.handled;
      //     }
      //   }
      // }
    print("KKK 1 = > ${focusIndex}");

      askFocus2.value = event;

      //ignore all events in case options dialog is showing
      return KeyEventResult.handled;
    }

    _cancelAndRestartTimer();

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      notifier.naviagte(NaviationType.FORWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      notifier.naviagte(NaviationType.BACKWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      notifier.naviagte(NaviationType.BACKWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      notifier.naviagte(NaviationType.FORWARD);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      // Pass key events to children
      for (var child in node.children) {
        if (child.onKeyEvent != null) {
          // Propagate the event to the child
          KeyEventResult childResult = child.onKeyEvent!(child, event);
          if (childResult == KeyEventResult.handled) {
            // If the child handles the event, stop propagating
            return KeyEventResult.handled;
          }
        }
      }
    }

    // if (event is RawKeyDownEvent) {
    //           _cancelAndRestartTimer();
    //           RawKeyDownEvent rawKeyDownEvent = event;
    //           debugPrint("OK =====> ${event.logicalKey.keyLabel}");
    //           if (event.logicalKey.keyLabel == KEY_CENTER) {
    //             _playPause();
    //           }
    //           if (event.logicalKey.keyLabel == KEY_RIGHT) {
    //             Duration? p = await controller.position;
    //             controller.seekTo(Duration(milliseconds: p!.inMilliseconds + (10 * 1000)));
    //           }
    //           if (event.logicalKey.keyLabel == KEY_LEFT) {
    //             Duration? p = await controller.position;
    //             controller.seekTo(Duration(milliseconds: p!.inMilliseconds - (10 * 1000)));
    //           }
    //         }
    return KeyEventResult.ignored;
  }

  Widget _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return DPadeHelperWidget(
      focusIndex: 1,
      onPressed: () {
        _cancelAndRestartTimer();

        if (_videoPlayerValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: ColoredBox(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
                  _videoPlayerValue.volume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _playPause,
      child: DPadeHelperWidget(
        focusIndex: 4,
        onPressed: _playPause,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(
            left: 6.0,
            right: 6.0,
          ),
          child: AnimatedPlayPause(
            color: widget.iconColor,
            playing: controller.value.isPlaying,
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _videoPlayerValue.position;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _videoPlayerValue.duration - _videoPlayerValue.position;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  Widget _buildSubtitleToggle(Color iconColor, double barHeight) {
    //if don't have subtitle hiden button
    if (chewieController.subtitle?.isEmpty ?? true) {
      return const SizedBox();
    }
    return DPadeHelperWidget(
      onPressed: _subtitleToggle,
      focusIndex: 6,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(right: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          Icons.subtitles,
          color: _subtitleOn ? iconColor : Colors.grey[700],
          size: 16.0,
        ),
      ),
    );
  }

  void _subtitleToggle() {
    print("OKAY => _subtitleToggle");
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: DPadeHelperWidget(
        focusIndex: 3,
        onPressed: _skipBack,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          margin: const EdgeInsets.only(left: 10.0),
          padding: const EdgeInsets.only(
            left: 6.0,
            right: 6.0,
          ),
          child: Icon(
            CupertinoIcons.gobackward_15,
            color: iconColor,
            size: 18.0,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: DPadeHelperWidget(
        focusIndex: 5,
        onPressed: _skipForward,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(
            left: 6.0,
            right: 8.0,
          ),
          margin: const EdgeInsets.only(
            right: 8.0,
          ),
          child: Icon(
            CupertinoIcons.goforward_15,
            color: iconColor,
            size: 18.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();

        final chosenSpeed = await showCupertinoModalPopup<double>(
          context: context,
          semanticsDismissible: true,
          useRootNavigator: chewieController.useRootNavigator,
          builder: (context) => _PlaybackSpeedDialog(
            speeds: chewieController.playbackSpeeds,
            selected: _videoPlayerValue.playbackSpeed,
          ),
        );

        if (chosenSpeed != null) {
          controller.setPlaybackSpeed(chosenSpeed);

          selectedSpeed = chosenSpeed;
        }

        if (_videoPlayerValue.isPlaying) {
          _startHideTimer();
        }
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewY(0.0)
            ..rotateX(math.pi)
            ..rotateZ(math.pi * 0.8),
          child: Icon(
            Icons.speed,
            color: iconColor,
            size: 18.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          if (chewieController.allowFullScreen)
            _buildExpandButton(
              backgroundColor,
              iconColor,
              barHeight,
              buttonPadding,
            ),
          const Spacer(),
          if (chewieController.allowMuting)
            _buildMuteButton(
              controller,
              backgroundColor,
              iconColor,
              barHeight,
              buttonPadding,
            ),
        ],
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      notifier.hideStuff = false;

      _startHideTimer();
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;

      chewieController.toggleFullScreen();
      _expandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragUpdate: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.cupertinoProgressColors ??
              ChewieProgressColors(
                playedColor: const Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: const Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: const Color.fromARGB(
                  20,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    final isFinished = _videoPlayerValue.position >= _videoPlayerValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  Future<void> _skipBack() async {
    _cancelAndRestartTimer();
    final beginning = Duration.zero.inMilliseconds;
    final skip = (_videoPlayerValue.position - const Duration(seconds: 15))
        .inMilliseconds;
    await controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
    // Restoring the video speed to selected speed
    // A delay of 1 second is added to ensure a smooth transition of speed after reversing the video as reversing is an asynchronous function
    Future.delayed(const Duration(milliseconds: 1000), () {
      controller.setPlaybackSpeed(selectedSpeed);
    });
  }

  Future<void> _skipForward() async {
    _cancelAndRestartTimer();
    final end = _videoPlayerValue.duration.inMilliseconds;
    final skip = (_videoPlayerValue.position + const Duration(seconds: 15))
        .inMilliseconds;
    await controller.seekTo(Duration(milliseconds: math.min(skip, end)));
    // Restoring the video speed to selected speed
    // A delay of 1 second is added to ensure a smooth transition of speed after forwarding the video as forwaring is an asynchronous function
    Future.delayed(const Duration(milliseconds: 1000), () {
      controller.setPlaybackSpeed(selectedSpeed);
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.value.isBuffering;
    }

    setState(() {
      _videoPlayerValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    required List<double> speeds,
    required double selected,
  })  : _speeds = speeds,
        _selected = selected;

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoActionSheet(
      actions: _speeds
          .map(
            (e) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop(e);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (e == _selected)
                    Icon(Icons.check, size: 20.0, color: selectedColor),
                  Text(e.toString()),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
