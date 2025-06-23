import 'package:flutter/material.dart';
import 'pomodoro_timer_screen.dart';

class ManagementPage extends StatefulWidget {
  @override
  _ManagementPageState createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  bool isExpanded1 = false;
  bool isExpanded2 = false;
  bool isExpanded3 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Руководство')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpandableButton(
              titleWidget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Метод Помодоро',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showPomodoroDialog(context);
                    },
                    icon: Icon(Icons.play_circle_outline),
                    label: Text(""),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors .blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
              isExpanded: isExpanded1,
              onPressed: () {
                setState(() {
                  isExpanded1 = !isExpanded1;
                });
              },
              text: 'Учишься 25 минут (без отвлечений).\n '
                  'Делаешь 5 минут перерыв (отдых).\n '
                  'Повторяешь 4 раза \n',
            ),

            SizedBox(height: 10),

            _buildExpandableButton(
              titleWidget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Дедлайны' ,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              isExpanded: isExpanded2,
              onPressed: () {
                setState(() {
                  isExpanded2 = !isExpanded2;
                });
              },
              text: 'Ставить четкие сроки сдачи роботы,сессий,уроков - дедлайны \n'
                  'Как это можно риолизовать в приложений :\nМожно выбрать день срока в калиндоре и создать пометку об дедлайне ',
            ),
            SizedBox(height: 10),

            _buildExpandableButton(
              titleWidget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Метод SQ3R ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              isExpanded: isExpanded3,
              onPressed: () {
                setState(() {
                  isExpanded3 = !isExpanded3;
                });
              },
              text: 'Survey (Обзор) – Быстро просматриваешь текст, чтобы понять структуру \n'
                  'Question (Вопросы) – Формулируешь вопросы по теме \n'
                  'Read (Чтение) – Читаешь и ищешь ответы на свои вопросы \n'
                  'Recite (Пересказ) – Повторяешь материал своими словами \n'
                  'Review (Повторение) – Закрепляешь знания \n' ,
            ),
          ],
        ),
      ),
    );
  }
  void showPomodoroDialog(BuildContext context) {
    int studyTime = 25;
    int breakTime = 5;
    int repetitions = 4;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pomodoro'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Учёба (мин): $studyTime'),
                  Slider(
                    value: studyTime.toDouble(),
                    min: 10,
                    max: 60,
                    divisions: 10,
                    label: studyTime.toString(),
                    onChanged: (val) => setState(() => studyTime = val.toInt()),
                  ),
                  Text('Отдых (мин): $breakTime'),
                  Slider(
                    value: breakTime.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: breakTime.toString(),
                    onChanged: (val) => setState(() => breakTime = val.toInt()),
                  ),
                  Text('Повторы: $repetitions'),
                  Slider(
                    value: repetitions.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: repetitions.toString(),
                    onChanged: (val) => setState(() => repetitions = val.toInt()),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PomodoroTimerScreen(
                      study: studyTime,
                      rest: breakTime,
                      repeats: repetitions,
                    ),
                  ),
                );
              },
              child: Text("Старт",
                  style: TextStyle(color:Colors.white)
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandableButton({
    String? title,
    Widget? titleWidget,
    required bool isExpanded,
    required VoidCallback onPressed,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A4A4A),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          child: titleWidget ??
              Text(
                title ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        ),
        if (isExpanded) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
