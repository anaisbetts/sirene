import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sirene/app.dart';

import 'package:sirene/interfaces.dart';

class FirebaseStorageManager implements StorageManager {
  FirebaseStorageManager() {
    Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
  }

  @override
  Stream<List<Phrase>> getPhrases({Query query, UserInfo forUser}) {
    final userStream = forUser != null
        ? Observable.just(forUser)
        : App.locator.get<LoginManager>().getAuthState();

    return userStream.switchMap((u) {
      if (u == null) {
        return Observable.never();
      }

      final q = query ?? allPhrasesQuery(forUser: u);
      return q.snapshots().map(
          (xs) => xs.documents.map((x) => Phrase.fromDocument(x)).toList());
    });
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

    if (userInfo == null) {
      return null;
    }

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

    if (userInfo == null) {
      return;
    }

    final userRef =
        Firestore.instance.collection('users').document(userInfo.uid);
    final user = User.fromDocument(await userRef.get());

    user.lastCustomPhrase = phrase;
    user.lastCustomPhraseCreatedOn = DateTime.now();

    await user.toDocument(userRef);
  }

  Future<void> upsertSavedPhrase(Phrase phrase,
      {UserInfo forUser, bool addOnly = false}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;
    final phrasesList = Firestore.instance
        .collection('users')
        .document(userInfo.uid)
        .collection('phrases');

    final match = await phrasesList
        .where('text', isEqualTo: phrase.text)
        .limit(1)
        .getDocuments();

    if (match.documents.length > 0) {
      // NB: We add an addOnly feature here because otherwise,
      // accidentally adding an already-added phrase would clear
      // the recency information
      if (!addOnly) {
        await phrase.toDocument(match.documents[0].reference);
      }

      return;
    } else {
      await phrase.addToCollection(phrasesList);
    }
  }

  @override
  Future<void> deletePhrase(Phrase phrase, {UserInfo forUser}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;

    if (phrase.id == null) {
      throw Exception("Phrase ID can't be null!");
    }

    final phraseRef = Firestore.instance
        .collection('users')
        .document(userInfo.uid)
        .collection('phrases')
        .document(phrase.id);

    return phraseRef.delete();
  }

  @override
  Future<void> savePresentedPhrase(Phrase phrase, {UserInfo forUser}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;

    if (phrase.detectedLanguage != null) {
      final ur = Firestore.instance.collection('users').document(userInfo.uid);
      final user = User.fromDocument(await ur.get());

      user.recentlyUsedLanguages ??= [];
      user.recentlyUsedLanguages.add(phrase.detectedLanguage);
      while (user.recentlyUsedLanguages.length > kMaxRecentLanguageCount) {
        user.recentlyUsedLanguages.removeAt(0);
      }

      await user.toDocument(ur);
    }

    if (phrase.id == null) {
      await saveCustomPhrase(phrase.text, forUser: forUser);
    } else {
      phrase.usageCount ??= 0;
      phrase.usageCount++;
      phrase.recentUsages ??= [];

      phrase.recentUsages.add(DateTime.now());
      while (phrase.recentUsages.length > kMaxRecentUsagesCount) {
        phrase.recentUsages.removeAt(0);
      }

      await upsertSavedPhrase(phrase, forUser: forUser);
    }
  }

  Future<void> loadDefaultSavedPhrases({UserInfo forUser}) async {
    List<dynamic> phrases = jsonDecode(
        await rootBundle.loadString('resources/initial-phrases.json'));

    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;
    final phraseColl = Firestore.instance
        .collection('users')
        .document(userInfo.uid)
        .collection('phrases');

    await Future.wait(phrases.map((x) => phraseColl.add(x)));
  }

  @override
  Future<String> getRecentFallbackLanguage({UserInfo forUser}) async {
    final userInfo = forUser ?? App.locator.get<LoginManager>().currentUser;
    final user = User.fromDocument(await Firestore.instance
        .collection('users')
        .document(userInfo.uid)
        .get());

    if (user.recentlyUsedLanguages == null ||
        user.recentlyUsedLanguages.length < 1) {
      return null;
    }

    Map<String, int> stats = user.recentlyUsedLanguages.fold(Map(), (acc, x) {
      acc[x] ??= 0;
      acc[x] = acc[x] + 1;
      return acc;
    });

    return stats.entries.fold(null, (MapEntry<String, int> acc, x) {
      if (acc == null) return x;
      return (x.value > acc.value ? x : acc);
    }).key;
  }
}
