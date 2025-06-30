import 'package:flutter/material.dart';

class RepeatDialog extends StatefulWidget {
  final List<String> initialSelectedDays;
  final String taskTitle;
  final Function(List<String>) onRepeatDaysSelected;

  RepeatDialog({
    required this.initialSelectedDays,
    required this.taskTitle,
    required this.onRepeatDaysSelected,
  });

  @override
  _RepeatDialogState createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<RepeatDialog> {
  List<String> days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  late List<String> selectedDays;

  @override
  void initState() {
    super.initState();
    selectedDays = List.from(widget.initialSelectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Повторять задачу: ${widget.taskTitle}"),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: days.map((day) {
            bool isSelected = selectedDays.contains(day);
            return ChoiceChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (bool newSelection) {
                setState(() {
                  if (newSelection) {
                    selectedDays.add(day);
                  } else {
                    selectedDays.remove(day);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Отмена", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            widget.onRepeatDaysSelected(selectedDays);
            Navigator.pop(context);
          },
          child: Text("Сохранить",
              style: TextStyle(color:Colors.white)
          ),
        ),
      ],
    );
  }
}