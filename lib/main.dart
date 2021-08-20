import 'package:clay_containers/clay_containers.dart';
import 'package:equalizer/equalizer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool enableCustomEQ = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Equalizer.init(1);
  }

  // void getAudioSession() async {
  //   final session = await AudioSession.instance;
  //   await session.configure(AudioSessionConfiguration.music());
  // }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Equalizer.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Color.fromARGB(255, 44, 51, 61),
            Color.fromARGB(255, 18, 25, 31)
          ])),
          child: ListView(
            children: [
              Container(
                margin: EdgeInsets.only(
                    top: 16.0, left: 16.0, right: 16.0, bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicText(
                      'Equalizer',
                      style: NeumorphicStyle(
                        depth: 3,
                        color: Colors.white, //customize color here
                      ),
                      textStyle: NeumorphicTextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    NeumorphicSwitch(
                      duration: Duration(milliseconds: 10),
                      style: NeumorphicSwitchStyle(
                        activeTrackColor: Color.fromARGB(255, 232, 232, 232),
                      ),
                      value: enableCustomEQ,
                      onChanged: (value) {
                        Equalizer.setEnabled(value);
                        setState(() {
                          enableCustomEQ = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<int>>(
                future: Equalizer.getBandLevelRange(),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  return snapshot.connectionState == ConnectionState.done
                      ? CustomEQ(enableCustomEQ, snapshot.data)
                      : Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomEQ extends StatefulWidget {
  const CustomEQ(this.enabled, this.bandLevelRange);
  final bool? enabled;
  final List<int>? bandLevelRange;
  @override
  _CustomEQState createState() => _CustomEQState();
}

class _CustomEQState extends State<CustomEQ> {
  double? min, max;
  String? _selectedValue;
  Future<List<String>>? fetchPresets;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    min = widget.bandLevelRange![0].toDouble();
    max = widget.bandLevelRange![1].toDouble();
    fetchPresets = Equalizer.getPresetNames();
  }

  @override
  Widget build(BuildContext context) {
    int bandId = 0;

    return FutureBuilder<List<int>>(
      future: Equalizer.getCenterBandFreqs(),
      builder: (context, snapshot) {
        return snapshot.connectionState == ConnectionState.done
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: snapshot.data!
                        .map((freq) => _buildSliderBand(freq, bandId++))
                        .toList(),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildPresets(),
                  ),
                ],
              )
            : CircularProgressIndicator();
      },
    );
  }

  Widget _buildSliderBand(int freq, int bandId) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: FutureBuilder<int>(
            future: Equalizer.getBandLevel(bandId),
            builder: (context, snapshot) {
              return SliderTheme(
                data: SliderThemeData(
                    thumbColor: Colors.red,
                    overlayColor: Colors.red,
                    activeTrackColor: Colors.red,
                    valueIndicatorColor: Colors.red,
                    activeTickMarkColor: Colors.red),
                child: FlutterSlider(
                  disabled: !widget.enabled!,
                  axis: Axis.vertical,
                  rtl: true,
                  min: min,
                  max: max,
                  values: [snapshot.hasData ? snapshot.data!.toDouble() : 0],
                  onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                    Equalizer.setBandLevel(bandId, lowerValue.toInt());
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '${freq ~/ 1000} Hz',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPresets() {
    return FutureBuilder<List<String>>(
      future: fetchPresets,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final presets = snapshot.data;
          if (presets!.isEmpty) return Text('No presets available!');
          return Neumorphic(
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Available Presets',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              value: _selectedValue,
              onChanged: widget.enabled!
                  ? (String? value) {
                      Equalizer.setPreset(value);
                      setState(() {
                        _selectedValue = value!;
                      });
                    }
                  : null,
              items: presets.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          );
        } else if (snapshot.hasError)
          return Text(snapshot.error.toString());
        else
          return CircularProgressIndicator();
      },
    );
  }
}
