import 'package:flutter/material.dart';

class GeometryFormulasPage extends StatefulWidget {
  @override
  State<GeometryFormulasPage> createState() => _GeometryFormulasPageState();
}

class _GeometryFormulasPageState extends State<GeometryFormulasPage> {
  final Map<String, List<Map<String, String>>> topics = {
    'Основные формулы': [
      {"title": "Площадь треугольника", "formula": "S = 1/2 * a * h", "note": "a — основание, h — высота"},
      {"title": "Площадь прямоугольника", "formula": "S = a * b", "note": "a и b — стороны прямоугольника"},
      {"title": "Площадь круга", "formula": "S = π * r²", "note": "r — радиус круга"},
      {"title": "Длина окружности", "formula": "C = 2 * π * r", "note": "r — радиус окружности"},
      {"title": "Теорема Пифагора", "formula": "c² = a² + b²", "note": "c — гипотенуза, a и b — катеты"},
    ],
    'Объёмы': [
      {"title": "Объём куба", "formula": "V = a³", "note": "a — сторона куба"},
      {"title": "Объём прямоугольного параллелепипеда", "formula": "V = a * b * c", "note": "a, b, c — измерения"},
      {"title": "Объём цилиндра", "formula": "V = π * r² * h", "note": "r — радиус, h — высота"},
      {"title": "Объём шара", "formula": "V = 4/3 * π * r³", "note": "r — радиус шара"},
    ],
  };

  Set<String> expandedTopics = {};
  final Map<String, Set<int>> expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Формулы по геометрии")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: topics.entries.map((topic) {
          final isTopicExpanded = expandedTopics.contains(topic.key);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (!expandedTopics.remove(topic.key)) {
                      expandedTopics.add(topic.key);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(topic.key, style: TextStyle(fontSize: 16)),
                    Icon(isTopicExpanded ? Icons.expand_less : Icons.expand_more)
                  ],
                ),
              ),
              if (isTopicExpanded)
                ...List.generate(topic.value.length, (index) {
                  final formula = topic.value[index];
                  final isExpanded = expandedItems[topic.key]?.contains(index) ?? false;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          expandedItems.putIfAbsent(topic.key, () => <int>{});
                          if (!expandedItems[topic.key]!.remove(index)) {
                            expandedItems[topic.key]!.add(index);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formula['title']!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text(formula['formula']!, style: TextStyle(fontSize: 16)),
                            if (isExpanded && formula['note'] != null) ...[
                              SizedBox(height: 8),
                              Text("Пояснение: ${formula['note']!}", style: TextStyle(fontSize: 14, color: Colors.white)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
