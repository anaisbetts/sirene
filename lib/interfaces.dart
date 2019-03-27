import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaguar_serializer/jaguar_serializer.dart';

part 'interfaces.jser.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}

abstract class StorageManager {
  Stream<List<Phrase>> getPhrasesForQuery(Query query);
}

class User {
  User({this.email, this.isAnonymous});

  String email;
  bool isAnonymous;
}

class Phrase {
  Phrase({this.text, this.spokenText, this.isReply});

  String text;
  String spokenText;
  bool isReply;

  static Phrase fromDocument(DocumentSnapshot ds) {
    return phraseSerializer.fromDocument(ds);
  }

  toDocument(DocumentReference dr) {
    return phraseSerializer.toDocument(this, dr);
  }
}

mixin FirebaseSerializerMixin<T> on Serializer<T> {
  T fromDocument(DocumentSnapshot ds) {
    return this.fromMap(ds.data);
  }

  toDocument(T item, DocumentReference dr) {
    return dr.setData(this.toMap(item));
  }
}

/*
 * Boring junk ahead
 */

@GenSerializer()
class PhraseJsonSerializer extends Serializer<Phrase>
    with _$PhraseJsonSerializer, FirebaseSerializerMixin<Phrase> {}

final phraseSerializer = PhraseJsonSerializer();

@GenSerializer()
class UserJsonSerializer extends Serializer<User> with _$UserJsonSerializer {}

final userSerializer = UserJsonSerializer();
