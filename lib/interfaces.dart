import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}

class Phrase {
  Phrase({this.text, this.writtenText, this.isReply});

  String text;
  String writtenText;

  bool isReply;

  static Phrase fromDocument(DocumentSnapshot ds) {
    return Phrase(
        text: ds.data['text'],
        writtenText: ds.data['writtenText'],
        isReply: ds.data['isReply']);
  }
}

abstract class StorageManager {
  Stream<List<Phrase>> getPhrasesForQuery(Query query);
}
