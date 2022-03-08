import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NameChangePage extends StatefulWidget {
  final String mailad;
  const NameChangePage(this.mailad);
  @override
  _NameChangePageState createState() => _NameChangePageState();
}

class _NameChangePageState extends State<NameChangePage> {
  String name = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('名前変更'),
      ),
      body: Container(
        color: Colors.orange[50],
        padding: EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            TextFormField(
              decoration: InputDecoration(
                hintText: '名前',
                border: const OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  name = value;
                });
              },
            ),
            RaisedButton(
              child: Text('ユーザー登録'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('guest') // コレクションID指定
                    .doc(widget.mailad)
                    .update({
                  'name': name,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
