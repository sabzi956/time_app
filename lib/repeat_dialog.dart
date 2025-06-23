import 'package:flutter/material.dart';
import 'dart:convert';

class RepeatDialog extends StatefulWidget {
  final Map<String, String> task;
  final Function(List<String>) onRepeatDaysSelected;

  RepeatDialog({required this.task, required this.onRepeatDaysSelected});

  @override
  _RepeatDialogState createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<RepeatDialog> {
  List<String> days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  List<String> selectedDays = [];

  @override
  void initState() {
    super.initState();

    if (widget.task["repeatDays"] != null && widget.task["repeatDays"]!.isNotEmpty) {
      selectedDays = List<String>.from(jsonDecode(widget.task["repeatDays"]!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task["title"] ?? "Задача"),
      content: Wrap(
        spacing: 8,
        children: days.map((day) {
          bool isSelected = selectedDays.contains(day);
          return ChoiceChip(
            label: Text(day),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                if (isSelected) {
                  selectedDays.remove(day);
                } else {
                  selectedDays.add(day);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onRepeatDaysSelected(selectedDays);
            Navigator.pop(context);
          },
          child: Text("Сохранить",
              style: TextStyle(color:Colors.white)
          ),
        )
      ],
    );
  }
}


