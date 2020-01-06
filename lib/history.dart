import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'history_record.dart';

class HistoryPage extends StatelessWidget {
  final List<HistoryRecord> history;

  HistoryPage({Key key, @required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          return _buildTile(index);
        },
      ),
    );
  }

  ListTile _buildTile(int i) {
    var h = history[i];
    return ListTile(title: Text(h.title), subtitle: Text(h.description));
  }
}
