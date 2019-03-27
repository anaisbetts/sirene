import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sirene/interfaces.dart';

class FirebaseStorageManager extends StorageManager {
  @override
  Stream<List<Phrase>> getPhrasesForQuery(Query query) {
    return query
        .snapshots()
        .map((xs) => xs.documents.map((x) => Phrase.fromDocument(x)));
  }

  createPhrase(UserInfo user, Phrase phrase) async {
    final dr = await Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('phrases')
        .add({});

    phrase.toDocument(dr);
  }
}
