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
import 'dart:async';

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
  Map<String, List<Map<String, dynamic>>> tasksByDate = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTasks().then((_) {
      _checkTaskCompletion();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTaskCompletion();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<Map<String, dynamic>>> tasksToSave = {};
    tasksByDate.forEach((dateKey, tasks) {
      tasksToSave[dateKey] = tasks.map((task) {
        Map<String, dynamic> taskCopy = Map<String, dynamic>.from(task);
        taskCopy['isCompleted'] = taskCopy['isCompleted'].toString();
        return taskCopy;
      }).toList();
    });
    final jsonString = jsonEncode(tasksToSave);
    await prefs.setString('tasks_data', jsonString);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('tasks_data');
    if (jsonString != null) {
      setState(() {
        tasksByDate = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(jsonString).map((key, value) {
            List<dynamic> taskListDynamic = List<dynamic>.from(value);
            return MapEntry(key, taskListDynamic.map((item) {
              Map<String, dynamic> task = Map<String, dynamic>.from(item);
              if (task['repeatDays'] is String && task['repeatDays'].isNotEmpty) {
                try {
                  task['repeatDays'] = List<String>.from(jsonDecode(task['repeatDays']));
                } catch (e) {
                  task['repeatDays'] = [];
                }
              } else if (task['repeatDays'] == null) {
                task['repeatDays'] = [];
              }
              task['isCompleted'] = item['isCompleted'] == 'true';
              return task;
            }).toList());
          }),
        );
        _updateRepeatTasks();
      });
    }
  }

  void _updateRepeatTasks() {
    Map<String, List<Map<String, dynamic>>> tempTasksByDate = {};

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
              Map<String, dynamic> repeatedTask = Map<String, dynamic>.from(task);
              repeatedTask['isRepeatedInstance'] = true;

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

  void _checkTaskCompletion() {
    String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    DateTime now = DateTime.now();

    if (tasksByDate.containsKey(formattedCurrentDate)) {
      for (int i = 0; i < tasksByDate[formattedCurrentDate]!.length; i++) {
        Map<String, dynamic> task = tasksByDate[formattedCurrentDate]![i];
        List<String>? times = (task['time'] as String?)?.split(' - ');
        if (times != null && times.length == 2) {
          try {
            DateTime endTime = DateFormat('HH:mm').parse(times[1]);
            DateTime taskEndTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              endTime.hour,
              endTime.minute,
            );

            if (now.isAfter(taskEndTime) && !(task['isCompleted'] ?? false)) {
              setState(() {
                tasksByDate[formattedCurrentDate]![i]['isCompleted'] = true;
              });
              _saveTasks();
            }
          } catch (e) {}
        }
      }
    }
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
      _checkTaskCompletion();
    }
  }

  void _addTask({int? index}) {
    TextEditingController textController = TextEditingController();
    DateTime initialStartTime = DateTime.now();
    DateTime initialEndTime = DateTime.now().add(Duration(hours: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String? selectedType;
    List<String> repeatDays = [];
    bool isCompleted = false;

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
      isCompleted = taskToEdit['isCompleted'] ?? false;
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

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(index == null ? 'Добавить задачу' : 'Редактировать задачу'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateDialog) {
                  return Column(
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
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty && tempSelectedType != null) {
                  Map<String, dynamic> newTask = {
                    "title": textController.text,
                    "time": "${DateFormat('HH:mm').format(tempStartTime)} - ${DateFormat('HH:mm').format(tempEndTime)}",
                    "type": tempSelectedType!,
                    "repeatDays": jsonEncode(tempRepeatDays),
                    "isCompleted": isCompleted,
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
                  _checkTaskCompletion();

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
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<Map<String, dynamic>> tasks = tasksByDate[formattedDate] ?? [];

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
                _checkTaskCompletion();
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
                          _checkTaskCompletion();
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
                          _checkTaskCompletion();
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

                      bool isTaskCompleted = task['isCompleted'] ?? false;

                      return Card(
                        color: isTaskCompleted
                            ? _getTaskColor(task["type"]!).withOpacity(0.6)
                            : _getTaskColor(task["type"]!),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              isTaskCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isTaskCompleted ? Colors.greenAccent : Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                tasksByDate[formattedDate]![index]['isCompleted'] = !isTaskCompleted;
                              });
                              _saveTasks();
                            },
                          ),
                          title: Text(
                            tasks[index]['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isTaskCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tasks[index]['time']!,
                                style: TextStyle(color: Colors.white70),
                              ),
                              if (repeatDaysToDisplay.isNotEmpty)
                                Text(
                                  'Повтор: ${repeatDaysToDisplay.join(", ")}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (String value) {
                              if (value == 'repeat') {
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
                              } else if (value == 'edit') {
                                _addTask(index: index);
                              } else if (value == 'delete') {
                                setState(() {
                                  tasksByDate[formattedDate]!.removeAt(index);
                                });
                                _saveTasks();
                                _updateRepeatTasks();
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'repeat',
                                child: Text('Повтор'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Редактировать'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Удалить'),
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
