import 'package:flutter/material.dart';
import 'subject_books_page.dart';

class BooksCatalogPage extends StatelessWidget {
  final List<int> classes = List.generate(11, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Выберите класс')),
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classNum = classes[index];
          return ListTile(
            title: Text('Класс $classNum'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectBooksPage(classNum: classNum),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

