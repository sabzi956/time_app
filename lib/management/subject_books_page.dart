import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'pdf_viewer_page.dart';

class SubjectBooksPage extends StatefulWidget {
  final int classNum;
  SubjectBooksPage({required this.classNum});

  @override
  _SubjectBooksPageState createState() => _SubjectBooksPageState();
}

class _SubjectBooksPageState extends State<SubjectBooksPage> {
  List<Map<String, dynamic>> allBooks = [], filtered = [];
  TextEditingController ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadJson();
  }

  Future<void> loadJson() async {
    final text = await rootBundle.loadString('assets/books.json');
    final list = List<Map<String, dynamic>>.from(json.decode(text));
    setState(() {
      allBooks = list.where((b) => b['class'] == widget.classNum).toList();
      filtered = allBooks;
    });
  }

  void onSearch(String q) {
    setState(() {
      filtered = allBooks
          .where((b) => b['subject'].toString().toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<bool> hasInternet() async {
    final conn = await Connectivity().checkConnectivity();
    return conn != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Класс ${widget.classNum} – книги'),
      ),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.all(8),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Поиск по предмету...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearch,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Ничего не найдено'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final b = filtered[i];
                return ListTile(
                  title: Text(b['subject']),
                  trailing: Icon(Icons.picture_as_pdf),
                  onTap: () async {
                    if (!await hasInternet()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Нет интернета')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerPage(
                          pdfUrl: b['url'],
                          title: '${b['subject']} – класс ${widget.classNum}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
