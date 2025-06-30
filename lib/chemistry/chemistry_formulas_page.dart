import 'package:flutter/material.dart';

class ChemistryFormulasPage extends StatefulWidget {
  @override
  State<ChemistryFormulasPage> createState() => _ChemistryFormulasPageState();
}

class _ChemistryFormulasPageState extends State<ChemistryFormulasPage> {
  final Map<String, List<Map<String, String>>> topics = {
    'Основы химии': [
      {"title": "Молярная масса", "formula": "M = m / n", "note": "m — масса вещества, n — количество вещества"},
      {"title": "Массовая доля", "formula": "w = m_вещества / m_раствора", "note": "m_вещества — масса вещества, m_раствора — масса раствора"},
    ],
    'Законы химии': [
      {"title": "Закон сохранения массы", "formula": "m_реагентов = m_продуктов", "note": "масса веществ до и после реакции не изменяется"},
      {"title": "Закон Авогадро", "formula": "V = V_0 * n", "note": "V_0 = 22.4 л/моль — молярный объем газа"},
    ]
  };

  Set<String> expandedTopics = {};
  final Map<String, Set<int>> expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Формулы по химии")),
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
                  backgroundColor: Colors.teal,
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
