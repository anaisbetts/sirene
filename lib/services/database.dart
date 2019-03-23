import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sirene/interfaces.dart';

class FirebaseStorageManager extends StorageManager {
  @override
  Stream<List<Phrase>> getPhrasesForQuery(Query query) {
    return query
        .snapshots()
        .map((xs) => xs.documents.map((x) => Phrase.fromDocument(x)));
  }
}
