// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interfaces.dart';

// **************************************************************************
// JaguarSerializerGenerator
// **************************************************************************

abstract class _$PhraseJsonSerializer implements Serializer<Phrase> {
  @override
  Map<String, dynamic> toMap(Phrase model) {
    if (model == null) return null;
    Map<String, dynamic> ret = <String, dynamic>{};
    setMapValue(ret, 'text', model.text);
    setMapValue(ret, 'spokenText', model.spokenText);
    setMapValue(ret, 'isReply', model.isReply);
    return ret;
  }

  @override
  Phrase fromMap(Map map) {
    if (map == null) return null;
    final obj = new Phrase();
    obj.text = map['text'] as String;
    obj.spokenText = map['spokenText'] as String;
    obj.isReply = map['isReply'] as bool;
    return obj;
  }
}

abstract class _$UserJsonSerializer implements Serializer<User> {
  @override
  Map<String, dynamic> toMap(User model) {
    if (model == null) return null;
    Map<String, dynamic> ret = <String, dynamic>{};
    setMapValue(ret, 'email', model.email);
    setMapValue(ret, 'isAnonymous', model.isAnonymous);
    setMapValue(ret, 'lastCustomPhrase', model.lastCustomPhrase);
    setMapValue(ret, 'lastCustomPhraseCreatedOn',
        dateTimeUtcProcessor.serialize(model.lastCustomPhraseCreatedOn));
    return ret;
  }

  @override
  User fromMap(Map map) {
    if (map == null) return null;
    final obj = new User();
    obj.email = map['email'] as String;
    obj.isAnonymous = map['isAnonymous'] as bool;
    obj.lastCustomPhrase = map['lastCustomPhrase'] as String;
    obj.lastCustomPhraseCreatedOn = dateTimeUtcProcessor
        .deserialize(map['lastCustomPhraseCreatedOn'] as String);
    return obj;
  }
}
