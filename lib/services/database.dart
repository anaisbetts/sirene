import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sirene/app.dart';

import 'package:sirene/interfaces.dart';

class FirebaseStorageManager implements StorageManager {
  @override
  Stream<List<Phrase>> getPhrases({Query query}) {
    final q = query ?? allPhrasesQuery();
    return q
        .snapshots()
        .map((xs) => xs.documents.map((x) => Phrase.fromDocument(x)).toList());
  }

  createPhrase(UserInfo user, Phrase phrase) async {
    final dr = await Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('phrases')
        .add({});

    phrase.toDocument(dr);
  }

  @override
  Query allPhrasesQuery({UserInfo forUser}) {
    final user = forUser ?? App.locator.get<LoginManager>().currentUser;

    return Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('phrases');
  }
}
