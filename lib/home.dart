import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ClockScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final List<Map<String, dynamic>> tasks;
  final Function(DateTime) onDateChanged;

  ClockScreen({
    required this.startTime,
    required this.endTime,
    required this.tasks,
    required this.onDateChanged,
  });

  @override
  _ClockScreenState createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  double angle = 0;
  bool is24HourFormat = false;
  Timer? timer;
  bool isManualControl = false;
  final double handleRadius = 50.0;
  int selectedHour = 0;
  int selectedMinute = 0;
  DateTime selectedDate = DateTime.now();
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    is24HourFormat = prefs.getBool('is24HourFormat') ?? false;
  }
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is24HourFormat', is24HourFormat);
  }


  @override
  void initState() {
    super.initState();
    _loadPreferences().then((_) {
      setState(() {
        selectedDate = widget.startTime;
        _updateTime();
      });
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isManualControl) {
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour % (is24HourFormat ? 24 : 12);
    final minute = now.minute;

    setState(() {
      selectedHour = hour;
      selectedMinute = minute;
      angle = ((hour * 60 + minute) / (is24HourFormat ? 1440 : 720)) * 2 * pi - pi / 2;
    });
  }

  void _toggleFormat() {
    setState(() {
      is24HourFormat = !is24HourFormat;
      _updateTime();
    });
    Future.microtask(() => _savePreferences());
  }

  void _resetToCurrentTime() {
    setState(() {
      isManualControl = false;
      selectedDate = DateTime.now();
      widget.onDateChanged(selectedDate);
      _updateTime();
    });
  }

  void _updateAngle(Offset localPosition, Size size) {
    final center = size.center(Offset.zero);
    final handLength = size.width / 2;
    final handEnd = center + Offset(cos(angle) * handLength, sin(angle) * handLength);

    if ((localPosition - handEnd).distance > handleRadius) return;

    final touchVector = localPosition - center;
    double newAngle = atan2(touchVector.dy, touchVector.dx);

    int totalMinutes = (((newAngle + pi / 2) % (2 * pi)) / (2 * pi) * (is24HourFormat ? 1440 : 720)).round();
    int newHour = (totalMinutes ~/ 60) % (is24HourFormat ? 24 : 12);
    int newMinute = totalMinutes % 60;

    if (newHour < 0) {
      newHour += is24HourFormat ? 24 : 12;
    }


    DateTime newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      newHour,
      newMinute,
    );

    if (newHour < selectedHour && selectedHour >= (is24HourFormat ? 23 : 11)) {
      newDateTime = newDateTime.add(Duration(days: 1));
    } else
    if (newHour > selectedHour && selectedHour <= (is24HourFormat ? 0 : 1)) {
      newDateTime = newDateTime.subtract(Duration(days: 1));
    }

    setState(() {
      isManualControl = true;
      angle = newAngle;
      selectedHour = newHour;
      selectedMinute = newMinute;
      selectedDate = newDateTime;
      widget.onDateChanged(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: GestureDetector(
            onPanUpdate: (details) {
              _updateAngle(details.localPosition, Size(275, 275));
            },
            child: CustomPaint(
              size: Size(275, 275),
              painter: ClockPainter(
                angle,
                is24HourFormat,
                selectedHour,
                selectedMinute,
                widget.tasks,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _toggleFormat,
              child: Text(is24HourFormat ? "Формат : 12 часов" : "Формат : 24 часа"),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _resetToCurrentTime,
              child: Icon(Icons.restore , size: 25),
            ),
          ],
        ),
      ],
    );
  }
}

class ClockPainter extends CustomPainter {
  final double angle;
  final bool is24HourFormat;
  final int selectedHour;
  final int selectedMinute;
  final List<Map<String, dynamic>> tasks;

  ClockPainter(
      this.angle,
      this.is24HourFormat,
      this.selectedHour,
      this.selectedMinute,
      this.tasks,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paintCircle = Paint()..color = Colors.grey.shade800;
    final paintLine = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    canvas.drawCircle(center, radius, paintCircle);

    for (int i = 0; i < (is24HourFormat ? 24 : 12); i++) {
      int hour = (i == 0) ? (is24HourFormat ? 0 : 12) : i;
      double hourAngle = ((hour % (is24HourFormat ? 24 : 12)) * (2 * pi) / (is24HourFormat ? 24 : 12)) - pi / 2;

      final textOffset = center + Offset(
        cos(hourAngle) * (radius - 20),
        sin(hourAngle) * (radius - 20),
      );

      textPainter.text = TextSpan(
        text: "$hour",
        style: TextStyle(color: Colors.white, fontSize: 16 , fontWeight: FontWeight.bold,),
      );

      textPainter.layout();
      textPainter.paint(canvas, textOffset - Offset(textPainter.width / 2, textPainter.height / 2));
    }


    for (var task in tasks) {
      int startHour = task["startHour"];
      int startMinute = task["startMinute"];
      int endHour = task["endHour"];
      int endMinute = task["endMinute"];
      Color color = task["color"];

      double startAngle = ((startHour * 60 + startMinute) / (is24HourFormat ? 1440 : 720)) * 2 * pi - pi / 2;
      double endAngle = ((endHour * 60 + endMinute) / (is24HourFormat ? 1440 : 720)) * 2 * pi - pi / 2;

      Paint sectorPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      Path sectorPath = Path();
      sectorPath.moveTo(center.dx, center.dy);
      if (startAngle < endAngle) {

        sectorPath.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
        );
      } else {

        sectorPath.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          2 * pi - startAngle,
          false,
        );

        sectorPath.lineTo(center.dx, center.dy);
        sectorPath.moveTo(center.dx, center.dy);
        sectorPath.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          0,
          endAngle,
          false,
        );
      }


      sectorPath.close();
      canvas.drawPath(sectorPath, sectorPaint);
    }

    final handLength = radius * 1;
    final handEnd = center + Offset(cos(angle) * handLength, sin(angle) * handLength);

    canvas.drawLine(center, handEnd, paintLine);
    canvas.drawCircle(handEnd, 10, Paint()..color = Colors.blue);
    canvas.drawCircle(center, 33, Paint()..color = Colors.blue);

    final timeText = "${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";
    textPainter.text = TextSpan(
      text: timeText,
      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
