import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> tasksByDate;
  const TasksPage({super.key, required this.tasksByDate});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int pageOffset = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
  }

  Color _getTaskColor(String? type) {
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

  List<DateTime> _getDatesForOffset(int offset) {
    DateTime today = DateTime.now();
    DateTime startDate = today.add(Duration(days: offset * 6));
    return List.generate(6, (i) => startDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания по дням'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  pageOffset = index - 1000;
                });
              },
              itemBuilder: (context, index) {
                int realOffset = index - 1000;
                List<DateTime> currentDates = _getDatesForOffset(realOffset);

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: List.generate(6, (i) {
                            DateTime date = currentDates[i];
                            String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                            List<Map<String, dynamic>> tasks = widget.tasksByDate[formattedDate] ?? [];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              color: Colors.grey[600],
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: (){},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[400],
                                        foregroundColor: Colors.black87,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('dd MMM').format(date),
                                        style: const TextStyle(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: tasks.length,
                                        itemBuilder: (context, taskIndex) {
                                          final task = tasks[taskIndex];
                                          final taskColor = _getTaskColor(task['type']);
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: taskColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              task['title'] ?? '',
                                              style: const TextStyle(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
