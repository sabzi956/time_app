import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'settings.dart';
import 'home.dart';
import 'Theme.dart';
import 'management.dart';
import 'repeat_dialog.dart';
import 'tasks.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeNotifications();
  runApp(TimeManagementApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void initializeNotifications() async {
  tz.initializeTimeZones();

  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(settings);
}

class TimeManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.2),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: HomePage(),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


Color _getTaskColor(String type) {
  switch (type) {
    case "Хобби":
      return Colors.orange;
    case "Работа":
      return Colors.deepPurple;
    case "Учёба":
      return Colors.green;
    case "Спорт":
      return Colors.red;
    case "Отдых":
      return Colors.lightBlue;
    case "Другие дела":
      return Colors.grey;
    default:
      return Colors.blue;
  }
}


class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, String>>> tasksByDate = {};

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(tasksByDate);
    await prefs.setString('tasks_data', jsonString);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('tasks_data');
    if (jsonString != null) {
      setState(() {
        tasksByDate = Map<String, List<Map<String, String>>>.from(
          jsonDecode(jsonString).map((key, value) {
            List<Map<String, String>> taskList = List<Map<String, dynamic>>.from(value).map((item) => Map<String, String>.from(
                item.map((k, v) => MapEntry(k, v.toString())))).toList();
            return MapEntry(key, taskList);
          }),
        );
        _updateRepeatTasks();
      });
    }
  }

  void _updateRepeatTasks() {
    tasksByDate.forEach((date, tasks) {
      tasks.forEach((task) {
        List<String> repeatDays = jsonDecode(task['repeatDays'] ?? '[]');
        if (repeatDays.isNotEmpty) {
          repeatDays.forEach((repeatDay) {
            if (repeatDay != date) {
              DateTime newDate = _getDateForRepeatDay(date, repeatDay);
              String newDateStr = DateFormat('yyyy-MM-dd').format(newDate);
              if (!tasksByDate.containsKey(newDateStr)) {
                tasksByDate[newDateStr] = [];
              }
              tasksByDate[newDateStr]!.add(task);
            }
          });
        }
      });
    });
  }

  DateTime _getDateForRepeatDay(String date, String repeatDay) {
    DateTime baseDate = DateFormat('yyyy-MM-dd').parse(date);
    Map<String, int> dayMap = {
      'ПН': 0,
      'ВТ': 1,
      'СР': 2,
      'ЧТ': 3,
      'ПТ': 4,
      'СБ': 5,
      'ВС': 6,
    };
    int targetDay = dayMap[repeatDay]!;
    int daysToAdd = (targetDay - baseDate.weekday + 7) % 7;
    return baseDate.add(Duration(days: daysToAdd));
  }

  Future<void> scheduleNotification(DateTime startTime, String title) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Напоминания',
      channelDescription: 'Уведомления о задачах',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      'Время выполнить задачу!',
      tz.TZDateTime.from(startTime, tz.local),
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addTask({int? index}) {
    TextEditingController textController = TextEditingController();
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(Duration(hours: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String? selectedType;

    if (index != null) {
      textController.text = tasksByDate[formattedDate]![index]['title']!;
      selectedType = tasksByDate[formattedDate]![index]['type']!;
      startTime = DateFormat('HH:mm').parse(tasksByDate[formattedDate]![index]['time']!.split(' - ')[0]);
      endTime = DateFormat('HH:mm').parse(tasksByDate[formattedDate]![index]['time']!.split(' - ')[1]);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Добавить задачу' : 'Редактировать задачу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, decoration: InputDecoration(labelText: 'Название')),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(labelText: "Тип задачи"),
                items: ["Хобби", "Работа", "Учёба", "Спорт", "Отдых", "Другие дела"].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                },
              ),
              SizedBox(height: 10),
              Text('Начало'),
              TimePickerSpinner(
                time: startTime,
                is24HourMode: true,
                normalTextStyle: TextStyle(fontSize: 18, color: Colors.grey),
                highlightedTextStyle: TextStyle(fontSize: 24, color: Colors.blue),
                spacing: 50,
                itemHeight: 50,
                isForce2Digits: true,
                onTimeChange: (time) {
                  setState(() {
                    startTime = time;
                  });
                },
              ),
              SizedBox(height: 10),
              Text('Конец'),
              TimePickerSpinner(
                time: endTime,
                is24HourMode: true,
                normalTextStyle: TextStyle(fontSize: 18, color: Colors.grey),
                highlightedTextStyle: TextStyle(fontSize: 24, color: Colors.blue),
                spacing: 50,
                itemHeight: 50,
                isForce2Digits: true,
                onTimeChange: (time) {
                  setState(() {
                    endTime = time;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty && selectedType != null) {
                  Map<String, dynamic> newTask = {
                    "title": textController.text,
                    "startTime": startTime,
                    "endTime": endTime,
                    "type": selectedType,
                    "color": _getTaskColor(selectedType!),
                    "repeatDays": jsonEncode([]),
                  };
                  if (!tasksByDate.containsKey(formattedDate))
                  {tasksByDate[formattedDate] = [];}

                  if (index == null) {
                    setState(() {
                      tasksByDate[formattedDate]!.add({
                        "title": newTask["title"],
                        "time": "${DateFormat('HH:mm').format(newTask["startTime"])} - ${DateFormat('HH:mm').format(newTask["endTime"])}",
                        "type": newTask["type"],
                        "repeatDays": newTask["repeatDays"],
                      });
                    });
                  } else {
                    setState(() {
                      tasksByDate[formattedDate]![index] = {
                        "title": newTask["title"],
                        "time": "${DateFormat('HH:mm').format(newTask["startTime"])} - ${DateFormat('HH:mm').format(newTask["endTime"])}",
                        "type": newTask["type"],
                        "repeatDays": newTask["repeatDays"],
                      };
                    });
                  }
                  _saveTasks();

                  if (textController.text.isNotEmpty && selectedType != null) {
                    DateTime now = DateTime.now();
                    if (startTime.isAfter(now)) {
                      scheduleNotification(startTime, textController.text);
                    }
                  }
                  Navigator.pop(context);
                }
              },
              child: Text('Сохранить',
                  style: TextStyle(color:Colors.white)
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<Map<String, String>> tasks = tasksByDate[formattedDate] ?? [];

    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(Duration(hours: 1));


    return Scaffold(
      appBar: AppBar(
        title: Text('Time Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.table_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TasksPage(tasksByDate: tasksByDate),
                ),
              ).then((_) {
                setState(() {});
              });
            },
          ),
        ],
      ),

      body:
      Column(
        children: [
          Expanded(
            flex: 2,
            child: ClockScreen(
              startTime: startTime,
              endTime: endTime,
              tasks: tasksByDate[formattedDate]?.map((task) {
                List<String>? times = task['time']?.split(' - ');
                return {
                  "startHour": int.parse(times![0].split(':')[0]),
                  "startMinute": int.parse(times[0].split(':')[1]),
                  "endHour": int.parse(times[1].split(':')[0]),
                  "endMinute": int.parse(times[1].split(':')[1]),
                  "color": _getTaskColor(task["type"]!),
                };
              }).toList() ?? [],

              onDateChanged: (newDate) {
                setState(() {
                  selectedDate = newDate;
                  startTime = DateTime(newDate.year, newDate.month, newDate.day, startTime.hour, startTime.minute);
                  endTime = DateTime(newDate.year, newDate.month, newDate.day, endTime.hour, endTime.minute);
                });
              },

            ),
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.subtract(Duration(days: 1));
                          });
                        },
                      ),
                      GestureDetector(onTap: () => _selectDate(context),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM').format(selectedDate),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(DateFormat('EEEE').format(selectedDate),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.add(Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        color: _getTaskColor(task["type"]!),
                        child: ListTile(
                          title: Text(tasks[index]['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tasks[index]['time']!),
                              if (tasks[index]['repeatDays'] != null && tasks[index]['repeatDays']!.isNotEmpty)
                                Text(jsonDecode(tasks[index]['repeatDays']!).join(", ")),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.repeat),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => RepeatDialog(
                                      task: task,
                                      onRepeatDaysSelected: (newDays) {
                                        setState(() {
                                          tasksByDate[formattedDate]![index]["repeatDays"] = jsonEncode(newDays);
                                        });
                                        _saveTasks();
                                      },
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _addTask(index: index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    tasksByDate[formattedDate]!.removeAt(index);
                                  });
                                  _saveTasks();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.book, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManagementPage()),
                );
              },
            ),

            Spacer(),

            FloatingActionButton(
              child: Icon(Icons.add_box, size: 40),
              onPressed: () => _addTask(),
            ),

            Spacer(),

            IconButton(
              icon: Icon(Icons.settings, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

