import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  // 最初に表示するWidget
  runApp(ChatApp());
}

// 更新可能なデータ
class UserState extends ChangeNotifier {
  FirebaseUser user;

  void setUser(FirebaseUser newUser) {
    user = newUser;
    notifyListeners();
  }
}

class ChatApp extends StatelessWidget {
  // ユーザーの情報を管理するデータ
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を渡す
    return ChangeNotifierProvider<UserState>.value(
      value: userState,
      child: MaterialApp(
        // 右上に表示される"debug"ラベルを消す
        debugShowCheckedModeBanner: false,
        // アプリ名
        title: 'ChatApp',
        theme: ThemeData(
          // テーマカラー
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // ログイン画面を表示
        home: LoginPage(),
      ),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';

  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // メールアドレス入力
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'メールアドレス',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              SizedBox(
                height: 3,
              ),
              // パスワード入力
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                // ユーザー登録ボタン
                child: RaisedButton(
                  color: Colors.cyan,
                  textColor: Colors.white,
                  child: Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final AuthResult result =
                          await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      final FirebaseUser user = result.user;

                      // ユーザー情報を更新
                      userState.setUser(user);

                      final date = DateTime(2000, 1, 1);
                      // ユーザー登録に成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      Firestore.instance
                          .collection('guest') // コレクションID指定
                          .document(email) // ドキュメントID自動生成
                          .setData({
                        'date': date,
                        'name': '名無し',
                        'mail': email,
                        'okuharayn': false,
                      });
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      setState(() {
                        infoText = "登録に失敗しました：${e.message}";
                      });
                    }
                  },
                ),
              ),
              Container(
                width: double.infinity,
                // ログイン登録ボタン
                child: OutlineButton(
                  textColor: Colors.cyan[700],
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final AuthResult result =
                          await auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      final FirebaseUser user = result.user;

                      // ユーザー情報を更新
                      userState.setUser(user);

                      // ログインに成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインに失敗しました：${e.message}";
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// チャット画面用Widget
class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
    final FirebaseUser user = userState.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            color: Colors.white,
            onPressed: () async {
              var okuharayn = await Firestore.instance
                  .collection('guest')
                  .document(user.email)
                  .get();
              if (okuharayn['okuharayn']) {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return ListPage();
                  }),
                );
              } else {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return ChatPage();
                  }),
                );
              }
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
                child: Text('ログイン情報：${user.email}'),
              ),
              Expanded(
                // StreamBuilder
                // 非同期処理の結果を元にWidgetを作れる
                child: StreamBuilder<QuerySnapshot>(
                  // 投稿メッセージ一覧を取得（非同期処理）
                  // 投稿日時でソート
                  stream: Firestore.instance
                      .collection('guest')
                      .document(user.email)
                      .collection('message')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // データが取得できた場合
                    if (snapshot.hasData) {
                      final List<DocumentSnapshot> documents =
                          snapshot.data.documents;
                      // 取得した投稿メッセージ一覧を元にリスト表示
                      return ListView(
                        reverse: true,
                        children: documents.map((document) {
                          return Card(
                            margin: document['email'] == 'gk3gogogo@gmail.com'
                                ? EdgeInsets.fromLTRB(0, 10, 50, 0)
                                : EdgeInsets.fromLTRB(50, 10, 0, 0),
                            child: Container(
                              color: document['email'] == 'gk3gogogo@gmail.com'
                                  ? Colors.cyan[50]
                                  : Colors.cyan[200],
                              child: ListTile(
                                leading:
                                    document['email'] == 'gk3gogogo@gmail.com'
                                        ? Icon(Icons.star)
                                        : null,
                                title: Text(document['text']),
                                trailing:
                                    document['email'] == 'gk3gogogo@gmail.com'
                                        ? null
                                        : Icon(Icons.star),
                              ),
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
              SizedBox(height: 70),
            ],
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                  color: Colors.cyan,
                  child: Row(
                    children: <Widget>[
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
                          color: Colors.cyan[800],
                        ),
                        onPressed: () async {
                          if (messageText != '') {
                            final date = DateTime.now()
                                .toLocal()
                                .toIso8601String(); // 現在の日時
                            final email = user.email; // AddPostPage のデータを参照
                            // 投稿データ用ドキュメント作成
                            await Firestore.instance
                                .collection('guest') // コレクションID指定
                                .document(email)
                                .collection('message')
                                .document()
                                .setData({
                              'text': messageText,
                              'email': email,
                              'date': date
                            });
                            await Firestore.instance
                                .collection('guest') // コレクションID指定
                                .document(email)
                                .updateData({'date': date});
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

// 管理者用ゲスト管理Widget
class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            // StreamBuilder
            // 非同期処理の結果を元にWidgetを作れる
            child: StreamBuilder<QuerySnapshot>(
              // 投稿メッセージ一覧を取得（非同期処理）
              // 投稿日時でソート
              stream: Firestore.instance
                  .collection('guest')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents =
                      snapshot.data.documents;
                  // 取得した投稿メッセージ一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {
                      return Card(
                        margin: EdgeInsets.fromLTRB(0, 5, 50, 0),
                        child: ListTile(
                          leading: Icon(Icons.star),
                          title: Text(document['name']),
                          subtitle: Text(document['mail']),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return ListChatPage(document['mail']);
                              }),
                            );
                          },
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
        ],
      ),
    );
  }
}

// 管理者用チャットWidget
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
    final FirebaseUser user = userState.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              if (user.email == 'gk3gogogo@gmail.com') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return ListPage();
                  }),
                );
              } else {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return ListPage();
                  }),
                );
              }
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
                child: Text('ログイン情報：${widget.mailad}'),
              ),
              Expanded(
                // StreamBuilder
                // 非同期処理の結果を元にWidgetを作れる
                child: StreamBuilder<QuerySnapshot>(
                  // 投稿メッセージ一覧を取得（非同期処理）
                  // 投稿日時でソート
                  stream: Firestore.instance
                      .collection('guest')
                      .document(widget.mailad)
                      .collection('message')
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    // データが取得できた場合
                    if (snapshot.hasData) {
                      final List<DocumentSnapshot> documents =
                          snapshot.data.documents;
                      // 取得した投稿メッセージ一覧を元にリスト表示
                      return ListView(
                        children: documents.map((document) {
                          return Card(
                            margin: EdgeInsets.fromLTRB(0, 5, 50, 0),
                            child: ListTile(
                              leading: Icon(Icons.star),
                              title: Text(document['text']),
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
              SizedBox(height: 60),
            ],
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                  color: Colors.brown,
                  child: Row(
                    children: <Widget>[
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
                        icon: Icon(Icons.done_outline),
                        onPressed: () async {
                          final date = DateTime.now()
                              .toLocal()
                              .toIso8601String(); // 現在の日時
                          // 投稿データ用ドキュメント作成
                          await Firestore.instance
                              .collection('guest') // コレクションID指定
                              .document(widget.mailad)
                              .collection('message')
                              .document()
                              .setData({
                            'text': messageText,
                            'email': 'gk3gogogo@gmail.com',
                            'date': date
                          });
                          await Firestore.instance
                              .collection('guest') // コレクションID指定
                              .document(widget.mailad)
                              .updateData({'date': date});
                          _messageTextController.clear();
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
