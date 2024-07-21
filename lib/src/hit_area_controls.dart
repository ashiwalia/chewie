import 'package:chewie/src/brightness_widget.dart';
import 'package:chewie/src/volume_widget.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'center_play_button.dart';
import 'seek_control_button.dart';

class HitAreaControls extends StatefulWidget {
  const HitAreaControls({
    Key? key,
    required this.onTapPlay,
    required this.onPressedPlay,
    required this.backgroundColor,
    required this.iconColor,
    required this.isFinished,
    required this.isPlaying,
    required this.showPlayButton,
    required this.showSeekButton,
    this.seekRewind,
    this.seekForward,
  }) : super(key: key);

  final VoidCallback onTapPlay;
  final VoidCallback onPressedPlay;
  final VoidCallback? seekRewind;
  final VoidCallback? seekForward;
  final Color backgroundColor;
  final Color iconColor;
  final bool isFinished;
  final bool isPlaying;
  final bool showPlayButton;
  final bool showSeekButton;

  @override
  State<HitAreaControls> createState() => _HitAreaControlsState();
}

class _HitAreaControlsState extends State<HitAreaControls> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showSeekButton) ...[
            SizedBox(width: 10),
            VolumeWidget(),
          ],
          widget.showSeekButton
              ? SeekControlButton(
                  backgroundColor: widget.backgroundColor,
                  iconColor: widget.iconColor,
                  onPressed: widget.seekRewind,
                  onDoublePressed: widget.seekRewind,
                  icon: Icons.fast_rewind,
                )
              : const SizedBox.shrink(),
          GestureDetector(
            onTap: widget.onTapPlay,
            child: CenterPlayButton(
              backgroundColor: widget.backgroundColor,
              iconColor: widget.iconColor,
              isFinished: widget.isFinished,
              isPlaying: widget.isPlaying,
              show: widget.showPlayButton,
              onPressed: widget.onPressedPlay,
            ),
          ),
          widget.showSeekButton
              ? SeekControlButton(
                  backgroundColor: widget.backgroundColor,
                  iconColor: widget.iconColor,
                  onPressed: widget.seekForward,
                  onDoublePressed: widget.seekForward,
                  icon: Icons.fast_forward,
                )
              : const SizedBox.shrink(),
          if (widget.showSeekButton) ...[
            BrightnessWidget(),
            SizedBox(width: 20)
          ],
        ],
      ),
    );
  }
}
