import 'package:flutter/material.dart';
import 'dart:async'; // Import dart:async for Timer

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispenser Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showGif = true;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      setState(() {
        _showGif = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً'),
      ),
      body: Stack(
        children: [
          // Background GIF
          AnimatedOpacity(
            opacity: _showGif ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Image.asset(
              'app/img/wave.gif', // Specify the path to your GIF file
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Container(
            color: _showGif ? Colors.transparent : Colors.white,
            child: Center(
              child: PinEntryField(),
            ),
          ),
        ],
      ),
    );
  }
}

class PinEntryField extends StatefulWidget {
  @override
  _PinEntryFieldState createState() => _PinEntryFieldState();
}

class _PinEntryFieldState extends State<PinEntryField> {
  String _pin = '';
  final String correctPin = '0001';

  void _submitPin(BuildContext context) {
    if (_pin == correctPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DispenserControlPage()),
      );
    } else {
      _showSnackBar(context, 'الرقم السري غير صحيح. يرجى المحاولة مرة أخرى.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 200,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTap: () {
              _showPinDialog(context);
            },
            child: Text(
              _pin.isEmpty ? 'ادخل الرقم السري' : '●●●●',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  void _showPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ادخل الرقم السري'),
          content: TextFormField(
            maxLength: 4,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            obscureText: true,
            onChanged: (value) {
              if (value.length <= 4) {
                setState(() {
                  _pin = value;
                });
              }
            },
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
              hintText: 'ادخل الرقم السري',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('تأكيد'),
              onPressed: () {
                _submitPin(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class DispenserControlPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحكم في الموزع'),
      ),
      body: Column(
        children: [
          Expanded(
            child: TrayList(),
          ),
          ClockWidget(),
        ],
      ),
    );
  }
}

class ClockWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Text(
          _getCurrentTime(),
          style: TextStyle(fontSize: 20),
        );
      },
    );
  }

  String _getCurrentTime() {
    var now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}

class TrayList extends StatefulWidget {
  @override
  _TrayListState createState() => _TrayListState();
}

class _TrayListState extends State<TrayList> {
  List<TimeOfDay?> _selectedTimes = List.generate(7, (_) => null);
  List<bool> _isPopupDisplayed = List.generate(7, (_) => false);

  @override
  void initState() {
    super.initState();
    _startSyncingTimers();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            title: Text('صينية ${index + 1}'),
            trailing: IconButton(
              icon: Icon(Icons.access_time),
              onPressed: () {
                _selectTime(context, index); // Pass the index to identify the tray
              },
            ),
          ),
        );
      },
    );
  }

  void _selectTime(BuildContext context, int trayIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[trayIndex] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[trayIndex] = picked;
      });
    }
  }

  void _startSyncingTimers() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      for (int i = 0; i < _selectedTimes.length; i++) {
        if (_selectedTimes[i] != null && !_isPopupDisplayed[i]) {
          var now = DateTime.now();
          if (now.hour == _selectedTimes[i]!.hour &&
              now.minute == _selectedTimes[i]!.minute &&
              now.second == 0) {
            _showPopupMessage(i);
          }
        }
      }
    });
  }

  void _showPopupMessage(int trayIndex) {
    setState(() {
      _isPopupDisplayed[trayIndex] = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('خذ حبتك'),
          content: Text('حان الوقت لتأخذ حبتك من الصينية ${trayIndex + 1}.'),
          actions: <Widget>[
            TextButton(
              child: Text('حسنًا'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
