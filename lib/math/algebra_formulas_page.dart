import 'package:flutter/material.dart';

class AlgebraFormulasPage extends StatefulWidget {
  @override
  State<AlgebraFormulasPage> createState() => _AlgebraFormulasPageState();
}

class _AlgebraFormulasPageState extends State<AlgebraFormulasPage> {
  final Map<String, List<Map<String, String>>> topics = {
    'сокращенное умножения': [
      {"title": "Квадрат суммы", "formula": "(a + b)² = a² + 2ab + b²", "note": "a, b — переменные"},
      {"title": "Квадрат разности", "formula": "(a - b)² = a² - 2ab + b²", "note": "a, b — переменные"},
      {"title": "Разность квадратов", "formula": "a² - b² = (a - b)(a + b)", "note": "a, b — переменные"},
      {"title": "Куб суммы", "formula": "(a + b)³ = a³ + 3a²b + 3ab² + b³", "note": "a, b — переменные"},
      {"title": "Куб разности", "formula": "(a - b)³ = a³ - 3a²b + 3ab² - b³", "note": "a, b — переменные"},
    ],
    'Квадратные уравнения': [
      {"title": "Квадратное уравнение", "formula": "ax² + bx + c = 0", "note": "a ≠ 0; x — переменная"},
      {"title": "Дискриминант", "formula": "D = b² - 4ac", "note": "a, b, c — коэффициенты"},
      {"title": "Корни уравнения", "formula": "x = (-b ± √D) / 2a", "note": "D — дискриминант"},
      {"title": "Формулы Виета", "formula": "x1 + x2 = -b/a, x1 * x2 = c/a", "note": "x1, x2 — корни уравнения"},
    ],
    'Свойства степеней': [
      {"title": "Сумма степеней с одним оснаванием ", "formula": "aⁿ * aᵐ = a^(n+m)", "note": "a = оснавание; n,m  — степень"},
      {"title": "Разность степеней с одним оснаванием", "formula": "aⁿ / aᵐ = a^(n-m)", "note": "a = оснавание; n,m  — степень"},
      {"title": "Умножение степеней", "formula": "(aⁿ)ᵐ = (aᵐ)ⁿ = a^(n*m)", "note": "a = оснавание; n,m  — степень"},
      {"title": "Умножение при одинаковом степений", "formula": "aⁿ * bⁿ = (a*b)ⁿ", "note": "a,b = оснавание; n  — степень"},
      {"title": "Диление при одинаковом степений", "formula": "aⁿ / bⁿ = (a/b)ⁿ", "note": "a,b = оснавание; n  — степень"},
      {"title": "Базавые свойства степеней", "formula": "a⁰ = 1 , a¹ = a , 1ⁿ = 1 , a-ⁿ = 1/aⁿ", "note": "a = оснавание; n  — степень"},
    ],
    'Логарифмы': [
      {"title": "Определение логарифма", "formula": "log(a)^(x) = b , a^b = x", "note": "a ≠ 1 , x > 0 , a > 0"},
      {"title": "Базавые свойства логарифма", "formula": "log(a)^(a) = 1 , log(a)^(1) = 0 , log(a)^(b) = 1/log(b)^(a) = 1", "note": "a,b — оснавание"},
      {"title": "Умножение аргументов логарифм", "formula": "log(a)^(x*y)= log(a)^(x) + log(a)^(y)", "note": "a = оснавание; x,y — аргументы"},
      {"title": "Диление аргументов логарифм", "formula": "log(a)^(x/y)= log(a)^(x) - log(a)^(y)", "note": "a = оснавание; x,y — аргументы"},
      {"title": "Степень оснавание и аргумента", "formula": "log(a)^(xⁿ) = n * log(a)^(x), log(aⁿ)^(x) = 1/n * log(a)^(x)", "note": "a = оснавание; x — аргументы; n — степень"},
      {"title": "переход на новое оснавание", "formula": "log(a)^(x) = log(c)^(x) / log(c)^(a)", "note": "c = оснавание; x,a — аргументы"},
    ],
    'Прогрессии': [
      {"title": "Арифметическая прогрессия", "formula": "a(n) = a(1) + d(n-1) , a(n) = a(n-1) + d", "note": "a — член Ариф.пр"},
      {"title": "Сумма Арифметическая прогрессия", "formula": "S(n) = (a(1) + a(n)/2)*n = (2a(1) + d(n-1)/2)*n ", "note": "S(n) — Сумма Ариф.пр"},
      {"title": "Геометрическая прогрессия", "formula": "b(n) = b(1) * q(n-1) , b(n) = b(n-1) * q", "note": "b — член Геом.пр"},
      {"title": "Сумма Геометрическая прогрессия", "formula": "S(n) = b(1)(1-qⁿ)/(1-q)", "note": "S(n) — Сумма Геом.пр"},
      {"title": "Суммв беск.убыв Геометрическая прогрессия", "formula": "S(n) = b(1)/(1-q)", "note": "|q|<1"},
    ],
    'Тригонометрия': [
      {"title": "Основное тригонометрическое тождество", "formula": "sin²x + cos²x = 1", "note": "x — угол"},
      {"title": "tg(x)", "formula": "tg(x) = sin(x) / cos(x)", "note": "tg(x) — тангенс угла x"},
      {"title": "ctg(x)", "formula": "ctg(x) = cos(x) / sin(x)", "note": "ctg(x) — котангенс угла x"},
      {"title": "tg²(x)+1", "formula": "1/cos²(x)", "note": "tg(x) — тангенс угла x"},
      {"title": "ctg²(x)+1", "formula": "1/sin²(x)", "note": "ctg(x) — котангенс угла x"},
      {"title": "sin(2x)", "formula": "2*sin(x)*cos(x)", "note": "x — угол"},
      {"title": "cos(2x)", "formula": "cos²(x) - sin²(x) = 2cos²(x) - 1 = 1 - 2sin²(x)", "note": "x — угол"},
      {"title": "tg(2x)", "formula": "2tg(x)/1-tg²(x)", "note": "x — угол"},
      {"title": "ctg(2x)", "formula": "ctg²(x)-1/2ctg(x)", "note": "x — угол"},
      {"title": "sin(x+y)", "formula": "sin(x) * cos(y) + cos(x) * sin(y)", "note": "x,y — углы"},
      {"title": "sin(x-y)", "formula": "sin(x) * cos(y) - cos(x) * sin(y)", "note": "x,y — углы"},
      {"title": "cos(x+y)", "formula": "cos(x) * cos(y) - sin(x) * sin(y)", "note": "x,y — углы"},
      {"title": "cos(x-y)", "formula": "cos(x) * cos(y) + sin(x) * sin(y)", "note": "x,y — углы"},
      {"title": "sin(x) + sin(y)", "formula": "2 sin(x+y/2) * cos(x-y/2)", "note": "x,y — углы"},
      {"title": "sin(x) - sin(y)", "formula": "2 sin(x-y/2) * cos(x+y/2)", "note": "x,y — углы"},
      {"title": "cos(x) + cos(y)", "formula": "2 cos(x+y/2) * cos(x-y/2)", "note": "x,y — углы"},
      {"title": "cos(x) - cos(y)", "formula": "-2 sin(x+y/2) * sin(x-y/2)", "note": "x,y — углы"},
      {"title": "sin(x) * sin(y)", "formula": "1/2(cos(x-y) - cos(x+y))", "note": "x,y — углы"},
      {"title": "cos(x) * cos(y)", "formula": "1/2(cos(x-y) + cos(x+y))", "note": "x,y — углы"},
      {"title": "sin(x) * cos(y)", "formula": "1/2(sin(x-y) + sin(x+y))", "note": "x,y — углы"},
    ],
    'Триг.уравнения': [
      {"title": "sin(x) = a", "formula": "x = (-1)ⁿ * arcsin(a) +πn , n = Z", "note": "arcsin(a)"},
      {"title": "sin(x) = a", "formula": "x(1)= arcsin(a) + 2πk, x(2)= π - arcsin(a) + 2πk, k = Z", "note": "arcsin(a)"},
      {"title": "cos(x) = a", "formula": "x = ±arccos(a) + 2πk, k = Z", "note": "arccos(a)"},
      {"title": "tg(x) = a", "formula": "x = arctg(a) + πk, k = Z", "note": "arctg(a)"},
      {"title": "ctg(x) = a", "formula": "x = arcctg(a) + πk, k = Z", "note": "arcctg(a)"},
      {"title": "sin(x) = 0", "formula": "x = πn", "note": "n = Z"},
      {"title": "sin(x) = 1", "formula": "x = π/2 + 2πn", "note": "n = Z"},
      {"title": "sin(x) = -1", "formula": "x = -π/2 + 2πn", "note": "n = Z"},
      {"title": "cos(x) = 0", "formula": "x = π/2 + πn", "note": "n = Z"},
      {"title": "cos(x) = 1", "formula": "x = 2πn", "note": "n = Z"},
      {"title": "cos(x) = -1", "formula": "x = π + 2πn", "note": "n = Z"},
      {"title": "tg(x) = 0", "formula": "x = πn", "note": "n = Z"},
      {"title": "ctg(x) = 0", "formula": "x = π/2 + πn", "note": "n = Z"},
    ],
  };

  Set<String> expandedTopics = {};
  final Map<String, Set<int>> expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Формулы по алгебре")),
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
                  backgroundColor: Colors.pink,
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
