const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onCreate = functions
  .region("asia-northeast1")
  .firestore.document("guest/{email}/message/{date}")
  .onCreate(async (snapshot, context) => {
    const email = context.params.email;
    console.log(email);
    const data = snapshot.data();

    if (data.email === email) {
      console.log("own message");
      // 管理人向けメッセージ
      const userDoc = await admin
        .firestore()
        .collection("guest")
        .doc("gk3gogogo@gmail.com")
        .get();
      const tokens = userDoc.get("token");
      if (tokens.length > 0) {
        const message = {
          notification: {
            title: "山田に相談だ",
            body: "ユーザー様からの新着メッセージがあります。",
          },
          tokens,
        };
        await admin.messaging().sendMulticast(message);
      }
      return;
    }
    console.log("reply message")
    const userDoc = await admin
      .firestore()
      .collection("guest")
      .doc(email)
      .get();
    const tokens = userDoc.get("token");
    if (!tokens) {
      console.log("not exist token");
      return;
    }
    if (tokens.length > 0) {
      const message = {
        notification: {
          title: "山田に相談だ",
          body: "新着メッセージがあります",
        },
        tokens,
      };
      await admin.messaging().sendMulticast(message);
    }
  });
