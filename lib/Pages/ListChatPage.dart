import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bubble/bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:yamadasoudan/UserState.dart';
import 'NameChangePage.dart';

class ListChatPage extends StatefulWidget {
  final String mailad;
  const ListChatPage(this.mailad);

  @override
  _ListChatPageState createState() => _ListChatPageState();
}

class _ListChatPageState extends State<ListChatPage> {
  // 入力した投稿メッセージ
  final _messageTextController = TextEditingController();
  String messageText = '';

  @override
  void dispose() {
    _messageTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user;
    File imageFile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('山田'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.person),
            color: Colors.white,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return NameChangePage(widget.mailad);
                }),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(8),
                child: Text('相手：${widget.mailad}'),
              ),
              Expanded(
                // StreamBuilder
                // 非同期処理の結果を元にWidgetを作れる
                child: Container(
                  color: Colors.orange[50],
                  child: StreamBuilder<QuerySnapshot>(
                    // 投稿メッセージ一覧を取得（非同期処理）
                    // 投稿日時でソート
                    stream: FirebaseFirestore.instance
                        .collection('guest')
                        .doc(widget.mailad)
                        .collection('message')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // データが取得できた場合
                      if (snapshot.hasData) {
                        final List<DocumentSnapshot> documents =
                            snapshot.data.docs;
                        // 取得した投稿メッセージ一覧を元にリスト表示
                        return ListView(
                          reverse: true,
                          children: documents.map((document) {
                            return Bubble(
                              stick: true,
                              padding: BubbleEdges.all(10),
                              margin: document['email'] == 'gk3gogogo@gmail.com'
                                  ? BubbleEdges.only(top: 15, right: 50)
                                  : BubbleEdges.only(top: 15, left: 50),
                              alignment:
                                  document['email'] == 'gk3gogogo@gmail.com'
                                      ? Alignment.topLeft
                                      : Alignment.topRight,
                              color: document['email'] == 'gk3gogogo@gmail.com'
                                  ? Colors.white
                                  : Colors.orange[300],
                              nip: document['email'] == 'gk3gogogo@gmail.com'
                                  ? BubbleNip.leftTop
                                  : BubbleNip.rightTop,
                              child: document['textyn']
                                  ? Text(
                                      document['text'],
                                      style: DefaultTextStyle.of(context)
                                          .style
                                          .apply(fontSizeFactor: 1.2),
                                    )
                                  : Image.network(
                                      document['url'],
                                      width: 200,
                                    ),
                            );
                          }).toList(),
                        );
                      }
                      // データが読込中の場合
                      return Center(
                        child: Text('読込中...'),
                      );
                    },
                  ),
                ),
              ),
              Container(
                height: 70,
                color: Colors.orange[50],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  color: Colors.orange,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () async {
                          final date = DateTime.now()
                              .toLocal()
                              .toIso8601String(); // 現在の日時
                          final email = user.email;
                          final picker = ImagePicker();
                          final pickedFile = await picker.getImage(
                              source: ImageSource.gallery);
                          imageFile = File(pickedFile.path);
                          final storage = FirebaseStorage.instance;
                          TaskSnapshot snapshot = await storage
                              .ref()
                              .child(" ${email}/${date} ")
                              .putFile(imageFile)
                              .whenComplete(() => null);
                          final String url =
                              await snapshot.ref.getDownloadURL();
                          // 投稿データ用ドキュメント作成
                          await FirebaseFirestore.instance
                              .collection('guest') // コレクションID指定
                              .doc(widget.mailad)
                              .collection('message')
                              .doc(date)
                              .set({
                            'url': url,
                            'email': email,
                            'date': date,
                            'textyn': false,
                          });
                        },
                      ),
                      Container(
                        width: 5,
                      ),
                      Flexible(
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'メッセージ',
                          ),
                          controller: _messageTextController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          minLines: 1,
                          onChanged: (String value) {
                            setState(() {
                              messageText = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.done_outline,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (messageText != '') {
                            final date = DateTime.now()
                                .toLocal()
                                .toIso8601String(); // 現在の日時
                            final email = user.email; // AddPostPage のデータを参照
                            // 投稿データ用ドキュメント作成
                            // ▼FirestoreをFirebaseFirestoreへ変更
                            await FirebaseFirestore.instance
                                .collection('guest') // コレクションID指定
                                .doc(widget.mailad)
                                .collection('message')
                                .doc(date)
                                .set({
                              'text': messageText,
                              'email': email,
                              'date': date,
                              'textyn': true
                            });
                            await FirebaseFirestore.instance
                                .collection('guest') // コレクションID指定
                                .doc(widget.mailad)
                                .update({'date': date});
                            _messageTextController.clear();
                            messageText = '';
                          }
                          FocusScope.of(context).requestFocus(new FocusNode());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
