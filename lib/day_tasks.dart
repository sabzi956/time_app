import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'repeat_dialog.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

class DayTasksScreen extends StatefulWidget {
  final DateTime initialDate;
  final VoidCallback? onTasksChanged;

  const DayTasksScreen({Key? key, required this.initialDate, this.onTasksChanged}) : super(key: key);

  @override
  _DayTasksScreenState createState() => _DayTasksScreenState();
}

class _DayTasksScreenState extends State<DayTasksScreen> {
  late DateTime displayDate;
  Map<String, List<Map<String, dynamic>>> tasksByDate = {};

  @override
  void initState() {
    super.initState();
    displayDate = widget.initialDate;
    _loadAndProcessTasks();
  }

  @override
  void didUpdateWidget(covariant DayTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      displayDate = widget.initialDate;
      _loadAndProcessTasks();
    }
  }

  Future<void> _loadAndProcessTasks() async {
    await _loadTasks();
    setState(() {
      _updateRepeatTasks();
      _checkTaskCompletion();
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('tasks_data');
    if (jsonString != null) {
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
    } else {
      tasksByDate = {};
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<Map<String, dynamic>>> tasksToSave = {};
    tasksByDate.forEach((dateKey, tasks) {
      tasksToSave[dateKey] = tasks.map((task) {
        Map<String, dynamic> taskCopy = Map<String, dynamic>.from(task);
        if (taskCopy['repeatDays'] is List<String>) {
          taskCopy['repeatDays'] = jsonEncode(taskCopy['repeatDays']);
        }
        taskCopy['isCompleted'] = taskCopy['isCompleted'].toString();
        return taskCopy;
      }).toList();
    });
    final jsonString = jsonEncode(tasksToSave);
    await prefs.setString('tasks_data', jsonString);
    widget.onTasksChanged?.call();
  }

  void _updateRepeatTasks() {
    Map<String, List<Map<String, dynamic>>> tempTasksForDisplay = {};

    tasksByDate.forEach((dateKey, tasks) {
      DateTime baseDate;
      try {
        baseDate = DateFormat('yyyy-MM-dd').parse(dateKey);
      } catch (e) {
        return;
      }

      for (var task in tasks) {
        List<String> repeatDays = [];
        if (task['repeatDays'] is List<dynamic>) {
          repeatDays = (task['repeatDays'] as List<dynamic>).cast<String>();
        } else if (task['repeatDays'] is String && task['repeatDays'].isNotEmpty) {
          try {
            repeatDays = List<String>.from(jsonDecode(task['repeatDays']));
          } catch (e) {
            repeatDays = [];
          }
        }

        if (!tempTasksForDisplay.containsKey(dateKey)) {
          tempTasksForDisplay[dateKey] = [];
        }

        bool originalTaskExists = tempTasksForDisplay[dateKey]!.any((existingTask) =>
        existingTask['title'] == task['title'] &&
            existingTask['time'] == task['time'] &&
            existingTask['type'] == task['type']
        );
        if (!originalTaskExists) {
          tempTasksForDisplay[dateKey]!.add(task);
        }


        if (repeatDays.isNotEmpty) {
          for (int i = -365; i < 366; i++) {
            DateTime currentDate = displayDate.add(Duration(days: i));
            String currentDayName = DateFormat('EE', 'ru_RU').format(currentDate);
            String newDateStr = DateFormat('yyyy-MM-dd').format(currentDate);

            if (repeatDays.contains(currentDayName)) {
              if (!tempTasksForDisplay.containsKey(newDateStr)) {
                tempTasksForDisplay[newDateStr] = [];
              }
              Map<String, dynamic> repeatedTask = Map<String, dynamic>.from(task);
              repeatedTask['isRepeatedInstance'] = true;
              bool taskExists = tempTasksForDisplay[newDateStr]!.any((existingTask) =>
              existingTask['title'] == repeatedTask['title'] &&
                  existingTask['time'] == repeatedTask['time'] &&
                  existingTask['type'] == repeatedTask['type']
              );

              if (!taskExists) {
                tempTasksForDisplay[newDateStr]!.add(repeatedTask);
              }
            }
          }
        }
      }
    });
    tasksByDate = tempTasksForDisplay;
  }

  void _checkTaskCompletion() {
    String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(displayDate);
    DateTime now = DateTime.now();

    if (tasksByDate.containsKey(formattedCurrentDate)) {
      for (int i = 0; i < tasksByDate[formattedCurrentDate]!.length; i++) {
        Map<String, dynamic> task = tasksByDate[formattedCurrentDate]![i];
        List<String>? times = (task['time'] as String?)?.split(' - ');
        if (times != null && times.length == 2) {
          try {
            DateTime endTime = DateFormat('HH:mm').parse(times[1]);
            DateTime taskEndTime = DateTime(
              displayDate.year,
              displayDate.month,
              displayDate.day,
              endTime.hour,
              endTime.minute,
            );

            if (now.isAfter(taskEndTime) && !(task['isCompleted'] ?? false)) {
              setState(() {
                tasksByDate[formattedCurrentDate]![i]['isCompleted'] = true;
              });
              _saveTasks();
            }
          } catch (e) {
            print("Ошибка парсинга времени задачи: $e");
          }
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
      displayDate.year,
      displayDate.month,
      displayDate.day,
      startTime.hour,
      startTime.minute,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      title.hashCode + scheduledTime.millisecondsSinceEpoch,
      title,
      'Время выполнить задачу!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _addTask({int? index, required DateTime targetDate}) {
    TextEditingController textController = TextEditingController();
    DateTime initialStartTime = DateTime(targetDate.year, targetDate.month, targetDate.day, DateTime.now().hour, DateTime.now().minute);
    DateTime initialEndTime = initialStartTime.add(Duration(hours: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);
    String? selectedType;
    List<String> currentRepeatDays = [];
    bool isCompleted = false;

    if (index != null && tasksByDate.containsKey(formattedDate) && tasksByDate[formattedDate]!.length > index) {
      final taskToEdit = tasksByDate[formattedDate]![index];
      textController.text = taskToEdit['title']!;
      selectedType = taskToEdit['type']!;
      List<String>? times = (taskToEdit['time'] as String?)?.split(' - ');
      if (times != null && times.length == 2) {
        initialStartTime = DateTime(targetDate.year, targetDate.month, targetDate.day,
            int.parse(times[0].split(':')[0]), int.parse(times[0].split(':')[1]));
        initialEndTime = DateTime(targetDate.year, targetDate.month, targetDate.day,
            int.parse(times[1].split(':')[0]), int.parse(times[1].split(':')[1]));
      }
      if (taskToEdit['repeatDays'] is List<dynamic>) {
        currentRepeatDays = (taskToEdit['repeatDays'] as List<dynamic>).cast<String>();
      } else if (taskToEdit['repeatDays'] is String && taskToEdit['repeatDays'].isNotEmpty) {
        try {
          currentRepeatDays = List<String>.from(jsonDecode(taskToEdit['repeatDays']));
        } catch (e) {
          currentRepeatDays = [];
        }
      }
      isCompleted = taskToEdit['isCompleted'] ?? false;
    }


    showDialog(
      context: context,
      builder: (context) {
        DateTime tempStartTime = initialStartTime;
        DateTime tempEndTime = initialEndTime;
        String? tempSelectedType = selectedType;

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
                            tempStartTime = DateTime(targetDate.year, targetDate.month, targetDate.day, time.hour, time.minute);
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
                            tempEndTime = DateTime(targetDate.year, targetDate.month, targetDate.day, time.hour, time.minute);
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
                  Map<String, dynamic> taskData = {
                    "title": textController.text,
                    "time": "${DateFormat('HH:mm').format(tempStartTime)} - ${DateFormat('HH:mm').format(tempEndTime)}",
                    "type": tempSelectedType!,
                    "repeatDays": currentRepeatDays,
                    "isCompleted": isCompleted,
                  };

                  setState(() {
                    if (!tasksByDate.containsKey(formattedDate)) {
                      tasksByDate[formattedDate] = [];
                    }
                    if (index == null) {
                      tasksByDate[formattedDate]!.add(taskData);
                    } else {
                      tasksByDate[formattedDate]![index] = taskData;
                    }
                  });
                  _saveTasks();
                  _loadAndProcessTasks();
                  Navigator.pop(context);

                  DateTime notificationTime = DateTime(
                    targetDate.year, targetDate.month, targetDate.day,
                    tempStartTime.hour, tempStartTime.minute,
                  );
                  if (notificationTime.isAfter(DateTime.now())) {
                    scheduleNotification(notificationTime, textController.text);
                  }
                }
              },
              child: Text('Сохранить', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(int index, String formattedDate) {
    setState(() {
      tasksByDate[formattedDate]!.removeAt(index);
    });
    _saveTasks();
    _loadAndProcessTasks();
  }

  void _showRepeatDialog(Map<String, dynamic> task, int index, String formattedDate) {
    List<String> currentRepeatDays = [];
    if (task['repeatDays'] is List<dynamic>) {
      currentRepeatDays = (task['repeatDays'] as List<dynamic>).cast<String>();
    } else if (task['repeatDays'] is String && task['repeatDays'].isNotEmpty) {
      try {
        currentRepeatDays = List<String>.from(jsonDecode(task['repeatDays']));
      } catch (e) {
      }
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RepeatDialog(
          initialSelectedDays: currentRepeatDays,
          taskTitle: task['title']!,
          onRepeatDaysSelected: (newDays) {
            setState(() {
              bool foundAndUpdatedOriginal = false;
              tasksByDate.forEach((dateKey, taskList) {
                for (int i = 0; i < taskList.length; i++) {
                  if (taskList[i]['title'] == task['title'] &&
                      taskList[i]['time'] == task['time'] &&
                      taskList[i]['type'] == task['type']) {
                    taskList[i]['repeatDays'] = newDays;
                    foundAndUpdatedOriginal = true;
                  }
                }
              });

              if (!foundAndUpdatedOriginal) {
                if (tasksByDate.containsKey(formattedDate) && tasksByDate[formattedDate]!.length > index) {
                  tasksByDate[formattedDate]![index]['repeatDays'] = newDays;
                }
              }
              _saveTasks();
              _loadAndProcessTasks();
            });
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    String formattedDisplayDate = DateFormat('yyyy-MM-dd').format(displayDate);
    List<Map<String, dynamic>> tasksForDisplayDate = tasksByDate[formattedDisplayDate] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Задания по дням'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            widget.onTasksChanged?.call();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      displayDate = displayDate.subtract(Duration(days: 1));
                    });
                    _loadAndProcessTasks();
                  },
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: displayDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != displayDate) {
                          setState(() {
                            displayDate = picked;
                          });
                          _loadAndProcessTasks();
                        }
                      },
                      child: Text(
                        DateFormat('EEEE, dd MMM', 'ru_RU').format(displayDate),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      displayDate = displayDate.add(Duration(days: 1));
                    });
                    _loadAndProcessTasks();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksForDisplayDate.isEmpty
                ? Center(
              child: Text(
                'На этот день задач нет!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: tasksForDisplayDate.length,
              itemBuilder: (context, index) {
                final task = tasksForDisplayDate[index];
                List<String> repeatDaysToDisplay = [];
                if (task['repeatDays'] is List<dynamic>) {
                  repeatDaysToDisplay = (task['repeatDays'] as List<dynamic>).cast<String>();
                } else if (task['repeatDays'] is String && task['repeatDays'].isNotEmpty) {
                  try {
                    repeatDaysToDisplay = List<String>.from(jsonDecode(task['repeatDays']));
                  } catch (e) {}
                }

                bool isTaskCompleted = task['isCompleted'] ?? false;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          tasksByDate[formattedDisplayDate]![index]['isCompleted'] = !isTaskCompleted;
                        });
                        _saveTasks();
                      },
                    ),
                    title: Text(
                      task['title']!,
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
                          task['time']!,
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
                          _showRepeatDialog(task, index, formattedDisplayDate);
                        } else if (value == 'edit') {
                          _addTask(index: index, targetDate: displayDate);
                        } else if (value == 'delete') {
                          _deleteTask(index, formattedDisplayDate);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(targetDate: displayDate),
        child: Icon(Icons.add),
      ),
    );
  }
}