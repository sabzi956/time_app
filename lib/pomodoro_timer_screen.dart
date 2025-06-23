import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroTimerScreen extends StatefulWidget {
  final int study;
  final int rest;
  final int repeats;

  PomodoroTimerScreen({required this.study, required this.rest, required this.repeats});

  @override
  _PomodoroTimerScreenState createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  late int totalSeconds;
  late int currentRound;
  bool isStudy = true;
  bool isPaused = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    currentRound = 1;
    totalSeconds = widget.study * 60;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (totalSeconds > 0) {
          totalSeconds--;
        } else {
          if (currentRound < widget.repeats) {
            isStudy = !isStudy;
            currentRound += isStudy ? 1 : 0;
            totalSeconds = (isStudy ? widget.study : widget.rest) * 60;
          } else {
            timer.cancel();
          }
        }
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    Navigator.pop(context);
  }

  void stopOnlyTimer() {
    timer?.cancel();
    timer = null;
    setState(() {
      isPaused = true;
    });
  }

  void resumeTimer() {
    setState(() {
      isPaused = false;
    });
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isStudy ? Colors.green[200] : Colors.blue[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              formatTime(totalSeconds),
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isPaused
                    ? ElevatedButton.icon(
                  onPressed: () {
                    resumeTimer();
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text('Старт'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
                    : ElevatedButton.icon(
                  onPressed: () {
                    stopOnlyTimer();
                  },
                  icon: Icon(Icons.pause),
                  label: Text('Стоп'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.exit_to_app),
                  label: Text('Выход'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
