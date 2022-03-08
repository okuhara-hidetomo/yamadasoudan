import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamadasoudan/UserState.dart';
import 'ChatPage.dart';

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

  Future<void> setToken(String token) async {
    print('setToken $token');
    await FirebaseFirestore.instance
        .collection('guest') // コレクションID指定
        .doc(email) // ドキュメントID自動生成
        .update({
      'token': FieldValue.arrayUnion([token]),
    });
  }

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // メールアドレス入力
                SizedBox(height: 70),
                Container(
                  height: 150,
                  width: 150,
                  child: Image.asset('images/rogoicon.png'),
                ),
                SizedBox(height: 20),

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    color: Colors.orange[700],
                    textColor: Colors.white,
                    child: Text('ユーザー登録'),
                    onPressed: () async {
                      try {
                        FirebaseMessaging messaging =
                            FirebaseMessaging.instance;
                        final token = await messaging.getToken();
                        // メール/パスワードでユーザー登録
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        // ▼AuthResultをUserCredentialへ変更
                        final UserCredential result =
                            await auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        // ▼FirebaseUserをUserへ変更
                        final User user = result.user;

                        // ユーザー情報を更新
                        userState.setUser(user);

                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString("email", email);

                        final date = DateTime(2000, 1, 1);
                        // ユーザー登録に成功した場合
                        // チャット画面に遷移＋ログイン画面を破棄
                        // ▼FirestoreをFirebaseFirestoreへ変更
                        await FirebaseFirestore.instance
                            .collection('guest') // コレクションID指定
                            .doc(email) // ドキュメントID自動生成
                            .set({
                          'date': date,
                          'name': '名無し',
                          'mail': email,
                          'okuharayn': false,
                          'token': token,
                        });
                        final settings = await messaging.requestPermission(
                          alert: true,
                          announcement: false,
                          badge: true,
                          carPlay: false,
                          criticalAlert: false,
                          provisional: false,
                          sound: true,
                        );
                        await setToken(token);
                        messaging.onTokenRefresh.listen((event) async {
                          await setToken(event);
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
                    splashColor: Colors.orange[900],
                  ),
                ),
                Container(
                  width: double.infinity,
                  // ログイン登録ボタン
                  child: OutlineButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    textColor: Colors.orange[900],
                    child: Text('ログイン'),
                    onPressed: () async {
                      try {
                        // メール/パスワードでログイン
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        // ▼AuthResultをUserCredentialへ修正
                        final UserCredential result =
                            await auth.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        final User user = result.user;

                        // ユーザー情報を更新
                        userState.setUser(user);

                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString("email", email);

                        FirebaseMessaging messaging =
                            FirebaseMessaging.instance;
                        final token = await messaging.getToken();
                        await setToken(token);
                        messaging.onTokenRefresh.listen((event) async {
                          await setToken(event);
                        });

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
                    splashColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
