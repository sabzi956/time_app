import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class SmartCalculatorPage extends StatefulWidget {
  @override
  _SmartCalculatorPageState createState() => _SmartCalculatorPageState();
}

class _SmartCalculatorPageState extends State<SmartCalculatorPage> {
  String _expression = '';
  String _result = '';

  void _onPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '<') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        try {
          final exp = _expression.replaceAll('×', '*').replaceAll('÷', '/');
          _result = _calculate(exp);
        } catch (e) {
          _result = 'Ошибка';
        }
      } else {
        _expression += value;
      }
    });
  }

  Color _getButtonColor(String label) {
    const blueButtons = ['(', ')', 'C', '<', '+', '-', '×', '÷'];

    if (blueButtons.contains(label)) {
      return Colors.blue;
    } else if (label == '=') {
      return Colors.green;
    } else {
      return Colors.grey[200]!;
    }
  }


  String _calculate(String expr) {
    try {
      final parser = Parser();
      final expression = parser.parse(expr);
      final context = ContextModel();
      double eval = expression.evaluate(EvaluationType.REAL, context);
      return eval.toString();
    } catch (e) {
      return 'Ошибка';
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '=', '+'],
      ['(', ')', 'C', '<']
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Калькулятор')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: TextStyle(color: Colors.white, fontSize: 32),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _result,
                    style: TextStyle(color: Colors.greenAccent, fontSize: 40),
                  ),
                ],
              ),
            ),
          ),
          ...buttons.map((row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((label) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () => _onPressed(label),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(label),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }
}
