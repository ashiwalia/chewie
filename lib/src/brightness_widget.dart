import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'app_colors.dart';

class BrightnessWidget extends StatefulWidget {
  const BrightnessWidget({Key? key}) : super(key: key);

  @override
  BrightnessWidgetState createState() => BrightnessWidgetState();
}

class BrightnessWidgetState extends State<BrightnessWidget> {
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();

    ScreenBrightness().current.then((value) {
      _sliderValue = value;
      print('currentBrightness 1: $_sliderValue');
      setState(() {});
    });
  }

  void getVolume() async {
    Future.delayed(Duration.zero, () async {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance.setScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set brightness';
    }
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
        child: Transform.scale(
          scale: 0.6,
          child: IntrinsicWidth(
            child: Row(
              children: [
                const Icon(
                  Icons.brightness_4,
                  color: Colors.white,
                ),
                const SizedBox(width: 8.0),
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
                    child: StreamBuilder<double>(
                        stream:
                            ScreenBrightness.instance.onCurrentBrightnessChanged,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            _sliderValue = snapshot.data!;
                          }
                          debugPrint('currentBrightness: $_sliderValue');
                          return Slider(
                            value: _sliderValue,
                            onChanged: setBrightness,
                            min: 0,
                            max: 1,
                            activeColor: Colors.white,
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
