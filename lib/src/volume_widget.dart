import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

import 'app_colors.dart';

class VolumeWidget extends StatefulWidget {
  const VolumeWidget({Key? key}) : super(key: key);

  @override
  _VolumeWidgetState createState() => _VolumeWidgetState();
}

class _VolumeWidgetState extends State<VolumeWidget> {
  double _sliderValue = 0.0;
  double _volumeListenerValue = 0;

  @override
  void initState() {
    super.initState();
    VolumeController().listener((volume) {
      setState(() => _volumeListenerValue = volume);
    });
    getVolume();
  }

  void getVolume() async {
    Future.delayed(Duration.zero, () async {
      _sliderValue = await VolumeController().getVolume();
      setState(() {});
    });
  }

  @override
  void dispose() {
    VolumeController().removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenOrientation = MediaQuery.of(context).orientation;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: screenOrientation == Orientation.landscape
            ? MediaQuery.of(context).size.height * 0.5
            : MediaQuery.of(context).size.width * 0.4,
        child: IntrinsicWidth(
          child: Row(
            children: [
              const SizedBox(
                width: 20
              ),
              RotatedBox(
                quarterTurns: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey.shade800.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    onChanged: (double value) {
                      setState(() {
                        _sliderValue = value;
                        VolumeController()
                            .setVolume(_sliderValue, showSystemUI: false);
                      });
                    },
                    min: 0,
                    max: 1,
                    activeColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              const Icon(
                Icons.volume_up,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
