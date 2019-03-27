import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}

class Phrase {
  Phrase({@required this.text, this.spokenText, this.isReply});

  String text;
  String spokenText;

  bool isReply;

  static Phrase fromDocument(DocumentSnapshot ds) {
    return Phrase(
        text: ds.data['text'],
        spokenText: ds.data['spokenText'],
        isReply: ds.data['isReply']);
  }

  toDocument(DocumentReference dr) {
    return dr.setData({
      'text': text,
      'spokenText': spokenText,
      'isReply': isReply,
    });
  }
}

abstract class StorageManager {
  Stream<List<Phrase>> getPhrasesForQuery(Query query);
}
