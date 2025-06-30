import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PeriodicTablePage extends StatefulWidget {
  @override
  State<PeriodicTablePage> createState() => _PeriodicTablePageState();
}

class _PeriodicTablePageState extends State<PeriodicTablePage> {
  List<ElementData> elements = [];

  @override
  void initState() {
    super.initState();
    _loadElements();
  }

  Future<void> _loadElements() async {
    final jsonString = await rootBundle.loadString('assets/periodic_table.json');
    final jsonList = json.decode(jsonString) as List;
    setState(() {
      elements = jsonList.map((e) => ElementData.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Таблица Менделеева')),
      body: elements.isEmpty
          ? Center(child: CircularProgressIndicator())
          : InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            defaultColumnWidth: FixedColumnWidth(50),
            border: TableBorder.all(color: Colors.grey),
            children: List.generate(10, (period) {
              return TableRow(
                children: List.generate(18, (group) {
                  final element = elements.firstWhere(
                        (e) => e.period == period + 1 && e.group == group + 1,
                    orElse: () => ElementData.empty(),
                  );
                  return element.isEmpty
                      ? Container(height: 50)
                      : GestureDetector(
                    onTap: () => _showElementDetails(context, element),
                    child: Container(
                      color: Colors.blue.shade100,
                      padding: EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(element.symbol, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${element.atomicNumber}', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showElementDetails(BuildContext context, ElementData element) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${element.symbol} — ${element.name}'),
        content: Text(
          'Атомный номер: ${element.atomicNumber}\n'
              'Группа: ${element.group}\n'
              'Период: ${element.period}\n'
              'Атомная масса: ${element.atomicMass ?? '-'}\n'
              'Категория: ${element.category ?? '-'}',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }
}

class ElementData {
  final String symbol;
  final String name;
  final int atomicNumber;
  final int group;
  final int period;
  final double? atomicMass;
  final String? category;

  ElementData({
    required this.symbol,
    required this.name,
    required this.atomicNumber,
    required this.group,
    required this.period,
    this.atomicMass,
    this.category,
  });

  factory ElementData.fromJson(Map<String, dynamic> json) {
    return ElementData(
      symbol: json['symbol'],
      name: json['name'],
      atomicNumber: json['number'],
      group: json['group'],
      period: json['period'],
      atomicMass: (json['atomic_mass'] as num?)?.toDouble(),
      category: json['category'],
    );
  }

  bool get isEmpty => symbol == '';

  factory ElementData.empty() => ElementData(
    symbol: '',
    name: '',
    atomicNumber: 0,
    group: 0,
    period: 0,
  );
}
