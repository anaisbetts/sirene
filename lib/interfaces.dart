import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaguar_serializer/jaguar_serializer.dart';

part 'interfaces.jser.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo get currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}

abstract class StorageManager {
  Query allPhrasesQuery({UserInfo forUser});
  Stream<List<Phrase>> getPhrases({Query query});

  Future<void> saveCustomPhrase(String phrase, {UserInfo forUser});
  Future<String> getCustomPhrase({UserInfo forUser});

  Future<void> addSavedPhrase(Phrase phrase, {UserInfo forUser});

  static isCustomPhraseExpired(DateTime forDate) {
    final expiration = forDate.add(Duration(hours: 1));
    return expiration.isBefore(DateTime.now());
  }
}

class User {
  User({this.email, this.isAnonymous});

  String email;
  bool isAnonymous;

  String lastCustomPhrase;
  DateTime lastCustomPhraseCreatedOn;

  static User fromDocument(DocumentSnapshot ds) {
    return userSerializer.fromDocument(ds);
  }

  Future<void> toDocument(DocumentReference dr) {
    return userSerializer.toDocument(this, dr);
  }
}

class Phrase {
  Phrase({this.text, this.spokenText, this.isReply});

  String text;
  String spokenText;
  bool isReply;

  static Phrase fromDocument(DocumentSnapshot ds) {
    return phraseSerializer.fromDocument(ds);
  }

  Future<void> toDocument(DocumentReference dr) {
    return phraseSerializer.toDocument(this, dr);
  }

  Future<void> addToCollection(CollectionReference cr) {
    return phraseSerializer.addToCollection(this, cr);
  }
}

mixin FirebaseSerializerMixin<T> on Serializer<T> {
  T fromDocument(DocumentSnapshot ds) {
    return this.fromMap(ds.data);
  }

  Future<void> toDocument(T item, DocumentReference dr) {
    return dr.setData(this.toMap(item));
  }

  Future<void> addToCollection(T item, CollectionReference cr) {
    return cr.add(this.toMap(item));
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
class UserJsonSerializer extends Serializer<User>
    with _$UserJsonSerializer, FirebaseSerializerMixin<User> {}

final userSerializer = UserJsonSerializer();
