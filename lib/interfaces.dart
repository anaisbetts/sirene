import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaguar_serializer/jaguar_serializer.dart';
import 'package:rxdart/rxdart.dart';

part 'interfaces.jser.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo get currentUser;

  Observable<UserInfo> getAuthState();

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}

abstract class StorageManager {
  Query allPhrasesQuery({UserInfo forUser});
  Stream<List<Phrase>> getPhrases({Query query, UserInfo forUser});

  Future<void> saveCustomPhrase(String phrase, {UserInfo forUser});
  Future<String> getCustomPhrase({UserInfo forUser});

  Future<void> upsertSavedPhrase(Phrase phrase,
      {UserInfo forUser, bool addOnly = false});

  Future<void> deletePhrase(Phrase phrase, {UserInfo forUser});

  Future<void> presentPhrase(Phrase phrase, {UserInfo forUser});

  static isCustomPhraseExpired(DateTime forDate) {
    final expiration = forDate.add(Duration(hours: 1));
    return expiration.isBefore(DateTime.now());
  }

  Future<void> loadDefaultSavedPhrases({UserInfo forUser});
}

abstract class FirebaseDocument {
  String id;
}

class User implements FirebaseDocument {
  User({this.email, this.isAnonymous});

  @ignore
  String id;

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

const kMaxRecentUsagesCount = 8;

class Phrase implements FirebaseDocument {
  Phrase({this.text, this.spokenText, this.isReply});

  @ignore
  String id;

  String text;
  String spokenText;
  bool isReply;

  List<DateTime> recentUsages;
  int usageCount;

  static Phrase fromDocument(DocumentSnapshot ds) {
    final ret = phraseSerializer.fromDocument(ds);

    ret.usageCount ??= 0;
    ret.recentUsages ??= [];
    return ret;
  }

  Future<void> toDocument(DocumentReference dr) {
    return phraseSerializer.toDocument(this, dr);
  }

  Future<void> addToCollection(CollectionReference cr) {
    return phraseSerializer.addToCollection(this, cr);
  }

  static List<Phrase> recencySort(List<Phrase> phrases, bool repliesFirst) {
    /*
     * replies mode:
     * 
     * is a reply =>
     * number of usages =>
     * recency of latest usage =>
     * alphebetical by text 
     * 
     * no replies mode:
     * 
     * number of usages =>
     * recency of latest usage => 
     * alphebetical by text 
     */

    final ret = phrases.toList();
    ret.sort((l, r) {
      if (repliesFirst && l.isReply != r.isReply) {
        return l.isReply ? -1 : 1;
      }

      if (l.usageCount != r.usageCount) {
        return r.usageCount.compareTo(l.usageCount);
      }

      if (l.recentUsages.length > 0 && r.recentUsages.length > 0) {
        var latestL = l.recentUsages.fold<DateTime>(
          DateTime.fromMicrosecondsSinceEpoch(0),
          (acc, x) => acc.isBefore(x) ? acc : x,
        );

        var latestR = l.recentUsages.fold<DateTime>(
          DateTime.fromMicrosecondsSinceEpoch(0),
          (acc, x) => acc.isBefore(x) ? acc : x,
        );

        if (!latestL.isAtSameMomentAs(latestR)) {
          return latestR.compareTo(latestL);
        }
      }

      return l.text.toLowerCase().compareTo(r.text.toLowerCase());
    });

    return ret;
  }
}

mixin FirebaseSerializerMixin<T extends FirebaseDocument> on Serializer<T> {
  T fromDocument(DocumentSnapshot ds) {
    final ret = this.fromMap(ds.data);
    ret.id = ds.documentID;

    return ret;
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
