import 'package:flutter/material.dart';

class PhysicsFormulasPage extends StatefulWidget {
  @override
  State<PhysicsFormulasPage> createState() => _PhysicsFormulasPageState();
}

class _PhysicsFormulasPageState extends State<PhysicsFormulasPage> {
  final Map<String, List<Map<String, String>>> topics = {
    'Механика': [
      {"title": "Скорость", "formula": "v = s / t", "note": "s — путь, t — время"},
      {"title": "Ускорение", "formula": "a = Δv / t", "note": "Δv — изменение скорости, t — время"},
      {"title": "Второй закон Ньютона", "formula": "F = m * a", "note": "m — масса, a — ускорение"},
    ],
    'Электродинамика': [
      {"title": "Закон Ома", "formula": "I = U / R", "note": "U — напряжение, R — сопротивление"},
      {"title": "Мощность тока", "formula": "P = U * I", "note": "U — напряжение, I — сила тока"},
    ]
  };

  Set<String> expandedTopics = {};
  final Map<String, Set<int>> expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Формулы по физике")),
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
                  backgroundColor: Colors.blueAccent,
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
