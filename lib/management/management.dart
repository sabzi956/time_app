import 'package:flutter/material.dart';
import '../pomodoro_timer_screen.dart';
import '../math/smart_calculator_page.dart';
import '../math/algebra_formulas_page.dart';
import '../math/geometry_formulas_page.dart';
import '../physics/physics_formulas_page.dart';
import '../chemistry/chemistry_formulas_page.dart';
import '../chemistry/periodic_table_page.dart';
import 'books_catalog_page.dart';

class ManagementPage extends StatefulWidget {
  @override
  _ManagementPageState createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  bool isPomodoroExpanded = false;
  bool isMathExpanded = false;
  bool isPhysicsExpanded = false;
  bool isChemistryExpanded = false;
  bool isBooksExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Для Учёбы')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStyledSectionButton(
              titleWidget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Метод Помодоро',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => showPomodoroDialog(context),
                    icon: Icon(Icons.play_circle_outline, color: Colors.white),
                  ),
                ],
              ),
              isExpanded: isPomodoroExpanded,
              onPressed: () => setState(() => isPomodoroExpanded = !isPomodoroExpanded),
              content: Text(
                '25 минут учёбы → 5 минут отдыха.\nПовторить 4 раза.',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            _buildStyledSectionButton(
              title: 'Математика',
              isExpanded: isMathExpanded,
              onPressed: () => setState(() => isMathExpanded = !isMathExpanded),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubButton("📷 калькулятор", () => Navigator.push(context, MaterialPageRoute(builder: (_) => SmartCalculatorPage()))),
                  _buildSubButton("📘 Формулы по алгебре", () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlgebraFormulasPage()))),
                  _buildSubButton("📗 Формулы по геометрии", () => Navigator.push(context, MaterialPageRoute(builder: (_) => GeometryFormulasPage()))),
                ],
              ),
            ),
            SizedBox(height: 10),
            _buildStyledSectionButton(
              title: 'Физика',
              isExpanded: isPhysicsExpanded,
              onPressed: () => setState(() => isPhysicsExpanded = !isPhysicsExpanded),
              content: _buildSubButton("📘 Формулы по физике", () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhysicsFormulasPage()))),
            ),
            SizedBox(height: 10),
            _buildStyledSectionButton(
              title: 'Химия',
              isExpanded: isChemistryExpanded,
              onPressed: () => setState(() => isChemistryExpanded = !isChemistryExpanded),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubButton("🧪 Формулы по химий", () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChemistryFormulasPage()))),
                  _buildSubButton("🧬 Таблица Менделеева", () => Navigator.push(context, MaterialPageRoute(builder: (_) => PeriodicTablePage()))),
                ],
              ),
            ),
            SizedBox(height: 10),
            _buildStyledSectionButton(
              title: 'Книги',
              isExpanded: isBooksExpanded,
              onPressed: () => setState(() => isBooksExpanded = !isBooksExpanded),
              content: _buildSubButton("📖 Каталог (1–11 классы)", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BooksCatalogPage()))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildStyledSectionButton({
    String? title,
    Widget? titleWidget,
    required bool isExpanded,
    required VoidCallback onPressed,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: titleWidget ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title ?? '',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: content,
            ),
          ),
      ],
    );
  }


  void showPomodoroDialog(BuildContext context) {
    int studyTime = 25;
    int breakTime = 5;
    int repetitions = 4;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pomodoro'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Учёба (мин): $studyTime'),
                  Slider(
                    value: studyTime.toDouble(),
                    min: 10,
                    max: 60,
                    divisions: 10,
                    label: studyTime.toString(),
                    onChanged: (val) => setState(() => studyTime = val.toInt()),
                  ),
                  Text('Отдых (мин): $breakTime'),
                  Slider(
                    value: breakTime.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: breakTime.toString(),
                    onChanged: (val) => setState(() => breakTime = val.toInt()),
                  ),
                  Text('Повторы: $repetitions'),
                  Slider(
                    value: repetitions.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: repetitions.toString(),
                    onChanged: (val) => setState(() => repetitions = val.toInt()),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PomodoroTimerScreen(
                      study: studyTime,
                      rest: breakTime,
                      repeats: repetitions,
                    ),
                  ),
                );
              },
              child: Text("Старт", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
