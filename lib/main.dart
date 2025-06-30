import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'settings.dart';
import 'home.dart';
import 'Theme.dart';
import 'management/management.dart';
import 'repeat_dialog.dart';
import 'tasks.dart';
import 'day_tasks.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('ru_RU', null);
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
    Map<String, List<Map<String, String>>> tempTasksByDate = {};

    tasksByDate.forEach((dateKey, tasks) {
      tempTasksByDate[dateKey] = List.from(tasks);
    });

    tasksByDate.forEach((dateKey, tasks) {
      DateTime baseDate;
      try {
        baseDate = DateFormat('yyyy-MM-dd').parse(dateKey);
      } catch (e) {
        return;
      }

      for (var task in tasks) {
        List<String> repeatDays = [];
        if (task['repeatDays'] != null && task['repeatDays'] is String) {
          try {
            repeatDays = List<String>.from(jsonDecode(task['repeatDays']!));
          } catch (e) {
            repeatDays = [];
          }
        } else if (task['repeatDays'] is List<dynamic>) {
          repeatDays = (task['repeatDays'] as List<dynamic>).cast<String>();
        }


        if (repeatDays.isNotEmpty) {
          for (int i = 0; i < 366; i++) {
            DateTime currentDate = baseDate.add(Duration(days: i));
            String currentDayName = DateFormat('EE', 'ru_RU').format(currentDate);
            String newDateStr = DateFormat('yyyy-MM-dd').format(currentDate);

            if (repeatDays.contains(currentDayName)) {
              if (!tempTasksByDate.containsKey(newDateStr)) {
                tempTasksByDate[newDateStr] = [];
              }
              Map<String, String> repeatedTask = Map<String, String>.from(task);

              bool taskExists = tempTasksByDate[newDateStr]!.any((existingTask) =>
              existingTask['title'] == repeatedTask['title'] &&
                  existingTask['time'] == repeatedTask['time'] &&
                  existingTask['type'] == repeatedTask['type']
              );

              if (!taskExists) {
                tempTasksByDate[newDateStr]!.add(repeatedTask);
              }
            }
          }
        }
      }
    });
    tasksByDate = tempTasksByDate;
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

    DateTime scheduledTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      title.hashCode + scheduledTime.millisecondsSinceEpoch,
      title,
      'Время выполнить задачу!',
      tz.TZDateTime.from(scheduledTime, tz.local),
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
    DateTime initialStartTime = DateTime.now();
    DateTime initialEndTime = DateTime.now().add(Duration(hours: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String? selectedType;
    List<String> repeatDays = [];

    if (index != null) {
      final taskToEdit = tasksByDate[formattedDate]![index];
      textController.text = taskToEdit['title']!;
      selectedType = taskToEdit['type']!;
      List<String>? times = (taskToEdit['time'] as String?)?.split(' - ');
      if (times != null && times.length == 2) {
        initialStartTime = DateFormat('HH:mm').parse(times[0]);
        initialEndTime = DateFormat('HH:mm').parse(times[1]);
      }
      if (taskToEdit['repeatDays'] != null && taskToEdit['repeatDays']!.isNotEmpty) {
        try {
          repeatDays = List<String>.from(jsonDecode(taskToEdit['repeatDays']!));
        } catch (e) {
          repeatDays = [];
        }
      }
    } else {
      initialStartTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, DateTime.now().hour, DateTime.now().minute);
      initialEndTime = initialStartTime.add(Duration(hours: 1));
    }

    showDialog(
      context: context,
      builder: (context) {
        DateTime tempStartTime = initialStartTime;
        DateTime tempEndTime = initialEndTime;
        String? tempSelectedType = selectedType;
        List<String> tempRepeatDays = List.from(repeatDays);

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return AlertDialog(
                contentPadding: EdgeInsets.zero,
                title: Text(index == null ? 'Добавить задачу' : 'Редактировать задачу'),
                content:SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  child:Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: textController, decoration: InputDecoration(labelText: 'Название')),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: tempSelectedType,
                        decoration: InputDecoration(labelText: "Тип задачи"),
                        items: ["Хобби", "Работа", "Учёба", "Спорт", "Отдых", "Другие дела"].map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            tempSelectedType = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      Text('Начало'),
                      TimePickerSpinner(
                        time: tempStartTime,
                        is24HourMode: true,
                        normalTextStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        highlightedTextStyle: TextStyle(fontSize: 24, color: Colors.blue),
                        spacing: 50,
                        itemHeight: 50,
                        isForce2Digits: true,
                        onTimeChange: (time) {
                          setStateDialog(() {
                            tempStartTime = time;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      Text('Конец'),
                      TimePickerSpinner(
                        time: tempEndTime,
                        is24HourMode: true,
                        normalTextStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        highlightedTextStyle: TextStyle(fontSize: 24, color: Colors.blue),
                        spacing: 50,
                        itemHeight: 50,
                        isForce2Digits: true,
                        onTimeChange: (time) {
                          setStateDialog(() {
                            tempEndTime = time;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty && tempSelectedType != null) {
                        Map<String, String> newTask = {
                          "title": textController.text,
                          "time": "${DateFormat('HH:mm').format(tempStartTime)} - ${DateFormat('HH:mm').format(tempEndTime)}",
                          "type": tempSelectedType!,
                          "repeatDays": jsonEncode(tempRepeatDays),
                        };
                        if (!tasksByDate.containsKey(formattedDate))
                        {tasksByDate[formattedDate] = [];}

                        if (index == null) {
                          setState(() {
                            tasksByDate[formattedDate]!.add(newTask);
                          });
                        } else {
                          setState(() {
                            tasksByDate[formattedDate]![index] = newTask;
                          });
                        }
                        _saveTasks();
                        _updateRepeatTasks();

                        DateTime notificationTime = DateTime(
                          selectedDate.year, selectedDate.month, selectedDate.day,
                          tempStartTime.hour, tempStartTime.minute,
                        );
                        if (notificationTime.isAfter(DateTime.now())) {
                          scheduleNotification(notificationTime, textController.text);
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
            });
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
        leading: IconButton(
          icon: Icon(Icons.edit_calendar),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DayTasksScreen(
                  initialDate: selectedDate,
                  onTasksChanged: () {
                    _loadTasks();
                  },
                ),
              ),
            ).then((_) {
              _loadTasks();
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TasksPage(tasksByDate: tasksByDate),
                ),
              ).then((_) {
                _loadTasks();
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
                      List<String> repeatDaysToDisplay = [];
                      if (task['repeatDays'] != null && task['repeatDays']!.isNotEmpty) {
                        try {
                          repeatDaysToDisplay = List<String>.from(jsonDecode(task['repeatDays']!));
                        } catch (e) {}
                      }

                      return Card(
                        color: _getTaskColor(task["type"]!),
                        child: ListTile(
                          title: Text(tasks[index]['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tasks[index]['time']!),
                              if (repeatDaysToDisplay.isNotEmpty)
                                Text('Повтор: ${repeatDaysToDisplay.join(", ")}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.repeat),
                                onPressed: () {
                                  List<String> currentRepeatDays = [];
                                  if (task['repeatDays'] != null && task['repeatDays']!.isNotEmpty) {
                                    try {
                                      currentRepeatDays = List<String>.from(jsonDecode(task['repeatDays']!));
                                    } catch (e) {}
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (context) => RepeatDialog(
                                      initialSelectedDays: currentRepeatDays,
                                      taskTitle: task['title']!,
                                      onRepeatDaysSelected: (newDays) {
                                        setState(() {
                                          tasksByDate[formattedDate]![index]["repeatDays"] = jsonEncode(newDays);
                                          _saveTasks();
                                          _updateRepeatTasks();
                                        });
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
                                  _updateRepeatTasks();
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
              child: Icon(Icons.add, size: 40),
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