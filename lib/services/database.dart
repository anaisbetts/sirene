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

  @override
  getCustomPhrase({UserInfo forUser}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;

    final user = User.fromDocument(await Firestore.instance
        .collection('users')
        .document(userInfo.uid)
        .get());

    if (user.lastCustomPhrase == null ||
        StorageManager.isCustomPhraseExpired(user.lastCustomPhraseCreatedOn)) {
      return null;
    }

    return user.lastCustomPhrase;
  }

  @override
  saveCustomPhrase(String phrase, {UserInfo forUser}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;

    final userRef =
        Firestore.instance.collection('users').document(userInfo.uid);
    final user = User.fromDocument(await userRef.get());

    user.lastCustomPhrase = phrase;
    user.lastCustomPhraseCreatedOn = DateTime.now();

    await user.toDocument(userRef);
  }
}
