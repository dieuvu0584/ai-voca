// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langCodeMeta = const VerificationMeta(
    'langCode',
  );
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
    'lang_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneticMeta = const VerificationMeta(
    'phonetic',
  );
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
    'phonetic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneticUKMeta = const VerificationMeta(
    'phoneticUK',
  );
  @override
  late final GeneratedColumn<String> phoneticUK = GeneratedColumn<String>(
    'phonetic_u_k',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUsMeta = const VerificationMeta(
    'audioUs',
  );
  @override
  late final GeneratedColumn<String> audioUs = GeneratedColumn<String>(
    'audio_us',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUkMeta = const VerificationMeta(
    'audioUk',
  );
  @override
  late final GeneratedColumn<String> audioUk = GeneratedColumn<String>(
    'audio_uk',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _definitionMeta = const VerificationMeta(
    'definition',
  );
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
    'definition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _definitionNativeMeta = const VerificationMeta(
    'definitionNative',
  );
  @override
  late final GeneratedColumn<String> definitionNative = GeneratedColumn<String>(
    'definition_native',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _romanizationMeta = const VerificationMeta(
    'romanization',
  );
  @override
  late final GeneratedColumn<String> romanization = GeneratedColumn<String>(
    'romanization',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceContextMeta = const VerificationMeta(
    'sourceContext',
  );
  @override
  late final GeneratedColumn<String> sourceContext = GeneratedColumn<String>(
    'source_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPhraseMeta = const VerificationMeta(
    'isPhrase',
  );
  @override
  late final GeneratedColumn<bool> isPhrase = GeneratedColumn<bool>(
    'is_phrase',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_phrase" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    word,
    langCode,
    phonetic,
    phoneticUK,
    audioUs,
    audioUk,
    partOfSpeech,
    definition,
    definitionNative,
    example,
    romanization,
    source,
    cachedAt,
    sourceType,
    sourceContext,
    isPhrase,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('lang_code')) {
      context.handle(
        _langCodeMeta,
        langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(
        _phoneticMeta,
        phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta),
      );
    }
    if (data.containsKey('phonetic_u_k')) {
      context.handle(
        _phoneticUKMeta,
        phoneticUK.isAcceptableOrUnknown(
          data['phonetic_u_k']!,
          _phoneticUKMeta,
        ),
      );
    }
    if (data.containsKey('audio_us')) {
      context.handle(
        _audioUsMeta,
        audioUs.isAcceptableOrUnknown(data['audio_us']!, _audioUsMeta),
      );
    }
    if (data.containsKey('audio_uk')) {
      context.handle(
        _audioUkMeta,
        audioUk.isAcceptableOrUnknown(data['audio_uk']!, _audioUkMeta),
      );
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('definition')) {
      context.handle(
        _definitionMeta,
        definition.isAcceptableOrUnknown(data['definition']!, _definitionMeta),
      );
    }
    if (data.containsKey('definition_native')) {
      context.handle(
        _definitionNativeMeta,
        definitionNative.isAcceptableOrUnknown(
          data['definition_native']!,
          _definitionNativeMeta,
        ),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('romanization')) {
      context.handle(
        _romanizationMeta,
        romanization.isAcceptableOrUnknown(
          data['romanization']!,
          _romanizationMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_context')) {
      context.handle(
        _sourceContextMeta,
        sourceContext.isAcceptableOrUnknown(
          data['source_context']!,
          _sourceContextMeta,
        ),
      );
    }
    if (data.containsKey('is_phrase')) {
      context.handle(
        _isPhraseMeta,
        isPhrase.isAcceptableOrUnknown(data['is_phrase']!, _isPhraseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word, langCode};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      langCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang_code'],
      )!,
      phonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic'],
      ),
      phoneticUK: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_u_k'],
      ),
      audioUs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_us'],
      ),
      audioUk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_uk'],
      ),
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      definition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition'],
      ),
      definitionNative: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_native'],
      ),
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      romanization: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}romanization'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      sourceContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_context'],
      ),
      isPhrase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_phrase'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final String word;
  final String langCode;
  final String? phonetic;
  final String? phoneticUK;
  final String? audioUs;
  final String? audioUk;
  final String? partOfSpeech;
  final String? definition;
  final String? definitionNative;
  final String? example;
  final String? romanization;
  final String source;
  final int? cachedAt;
  final String? sourceType;
  final String? sourceContext;
  final bool isPhrase;
  const Word({
    required this.word,
    required this.langCode,
    this.phonetic,
    this.phoneticUK,
    this.audioUs,
    this.audioUk,
    this.partOfSpeech,
    this.definition,
    this.definitionNative,
    this.example,
    this.romanization,
    required this.source,
    this.cachedAt,
    this.sourceType,
    this.sourceContext,
    required this.isPhrase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['lang_code'] = Variable<String>(langCode);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    if (!nullToAbsent || phoneticUK != null) {
      map['phonetic_u_k'] = Variable<String>(phoneticUK);
    }
    if (!nullToAbsent || audioUs != null) {
      map['audio_us'] = Variable<String>(audioUs);
    }
    if (!nullToAbsent || audioUk != null) {
      map['audio_uk'] = Variable<String>(audioUk);
    }
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    if (!nullToAbsent || definition != null) {
      map['definition'] = Variable<String>(definition);
    }
    if (!nullToAbsent || definitionNative != null) {
      map['definition_native'] = Variable<String>(definitionNative);
    }
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || romanization != null) {
      map['romanization'] = Variable<String>(romanization);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || cachedAt != null) {
      map['cached_at'] = Variable<int>(cachedAt);
    }
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceContext != null) {
      map['source_context'] = Variable<String>(sourceContext);
    }
    map['is_phrase'] = Variable<bool>(isPhrase);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      word: Value(word),
      langCode: Value(langCode),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      phoneticUK: phoneticUK == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUK),
      audioUs: audioUs == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUs),
      audioUk: audioUk == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUk),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      definition: definition == null && nullToAbsent
          ? const Value.absent()
          : Value(definition),
      definitionNative: definitionNative == null && nullToAbsent
          ? const Value.absent()
          : Value(definitionNative),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      romanization: romanization == null && nullToAbsent
          ? const Value.absent()
          : Value(romanization),
      source: Value(source),
      cachedAt: cachedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedAt),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceContext: sourceContext == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceContext),
      isPhrase: Value(isPhrase),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      word: serializer.fromJson<String>(json['word']),
      langCode: serializer.fromJson<String>(json['langCode']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      phoneticUK: serializer.fromJson<String?>(json['phoneticUK']),
      audioUs: serializer.fromJson<String?>(json['audioUs']),
      audioUk: serializer.fromJson<String?>(json['audioUk']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      definition: serializer.fromJson<String?>(json['definition']),
      definitionNative: serializer.fromJson<String?>(json['definitionNative']),
      example: serializer.fromJson<String?>(json['example']),
      romanization: serializer.fromJson<String?>(json['romanization']),
      source: serializer.fromJson<String>(json['source']),
      cachedAt: serializer.fromJson<int?>(json['cachedAt']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceContext: serializer.fromJson<String?>(json['sourceContext']),
      isPhrase: serializer.fromJson<bool>(json['isPhrase']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'langCode': serializer.toJson<String>(langCode),
      'phonetic': serializer.toJson<String?>(phonetic),
      'phoneticUK': serializer.toJson<String?>(phoneticUK),
      'audioUs': serializer.toJson<String?>(audioUs),
      'audioUk': serializer.toJson<String?>(audioUk),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'definition': serializer.toJson<String?>(definition),
      'definitionNative': serializer.toJson<String?>(definitionNative),
      'example': serializer.toJson<String?>(example),
      'romanization': serializer.toJson<String?>(romanization),
      'source': serializer.toJson<String>(source),
      'cachedAt': serializer.toJson<int?>(cachedAt),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceContext': serializer.toJson<String?>(sourceContext),
      'isPhrase': serializer.toJson<bool>(isPhrase),
    };
  }

  Word copyWith({
    String? word,
    String? langCode,
    Value<String?> phonetic = const Value.absent(),
    Value<String?> phoneticUK = const Value.absent(),
    Value<String?> audioUs = const Value.absent(),
    Value<String?> audioUk = const Value.absent(),
    Value<String?> partOfSpeech = const Value.absent(),
    Value<String?> definition = const Value.absent(),
    Value<String?> definitionNative = const Value.absent(),
    Value<String?> example = const Value.absent(),
    Value<String?> romanization = const Value.absent(),
    String? source,
    Value<int?> cachedAt = const Value.absent(),
    Value<String?> sourceType = const Value.absent(),
    Value<String?> sourceContext = const Value.absent(),
    bool? isPhrase,
  }) => Word(
    word: word ?? this.word,
    langCode: langCode ?? this.langCode,
    phonetic: phonetic.present ? phonetic.value : this.phonetic,
    phoneticUK: phoneticUK.present ? phoneticUK.value : this.phoneticUK,
    audioUs: audioUs.present ? audioUs.value : this.audioUs,
    audioUk: audioUk.present ? audioUk.value : this.audioUk,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    definition: definition.present ? definition.value : this.definition,
    definitionNative: definitionNative.present
        ? definitionNative.value
        : this.definitionNative,
    example: example.present ? example.value : this.example,
    romanization: romanization.present ? romanization.value : this.romanization,
    source: source ?? this.source,
    cachedAt: cachedAt.present ? cachedAt.value : this.cachedAt,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    sourceContext: sourceContext.present
        ? sourceContext.value
        : this.sourceContext,
    isPhrase: isPhrase ?? this.isPhrase,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      word: data.word.present ? data.word.value : this.word,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      phoneticUK: data.phoneticUK.present
          ? data.phoneticUK.value
          : this.phoneticUK,
      audioUs: data.audioUs.present ? data.audioUs.value : this.audioUs,
      audioUk: data.audioUk.present ? data.audioUk.value : this.audioUk,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      definition: data.definition.present
          ? data.definition.value
          : this.definition,
      definitionNative: data.definitionNative.present
          ? data.definitionNative.value
          : this.definitionNative,
      example: data.example.present ? data.example.value : this.example,
      romanization: data.romanization.present
          ? data.romanization.value
          : this.romanization,
      source: data.source.present ? data.source.value : this.source,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceContext: data.sourceContext.present
          ? data.sourceContext.value
          : this.sourceContext,
      isPhrase: data.isPhrase.present ? data.isPhrase.value : this.isPhrase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('word: $word, ')
          ..write('langCode: $langCode, ')
          ..write('phonetic: $phonetic, ')
          ..write('phoneticUK: $phoneticUK, ')
          ..write('audioUs: $audioUs, ')
          ..write('audioUk: $audioUk, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('definition: $definition, ')
          ..write('definitionNative: $definitionNative, ')
          ..write('example: $example, ')
          ..write('romanization: $romanization, ')
          ..write('source: $source, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('isPhrase: $isPhrase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    word,
    langCode,
    phonetic,
    phoneticUK,
    audioUs,
    audioUk,
    partOfSpeech,
    definition,
    definitionNative,
    example,
    romanization,
    source,
    cachedAt,
    sourceType,
    sourceContext,
    isPhrase,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.word == this.word &&
          other.langCode == this.langCode &&
          other.phonetic == this.phonetic &&
          other.phoneticUK == this.phoneticUK &&
          other.audioUs == this.audioUs &&
          other.audioUk == this.audioUk &&
          other.partOfSpeech == this.partOfSpeech &&
          other.definition == this.definition &&
          other.definitionNative == this.definitionNative &&
          other.example == this.example &&
          other.romanization == this.romanization &&
          other.source == this.source &&
          other.cachedAt == this.cachedAt &&
          other.sourceType == this.sourceType &&
          other.sourceContext == this.sourceContext &&
          other.isPhrase == this.isPhrase);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<String> word;
  final Value<String> langCode;
  final Value<String?> phonetic;
  final Value<String?> phoneticUK;
  final Value<String?> audioUs;
  final Value<String?> audioUk;
  final Value<String?> partOfSpeech;
  final Value<String?> definition;
  final Value<String?> definitionNative;
  final Value<String?> example;
  final Value<String?> romanization;
  final Value<String> source;
  final Value<int?> cachedAt;
  final Value<String?> sourceType;
  final Value<String?> sourceContext;
  final Value<bool> isPhrase;
  final Value<int> rowid;
  const WordsCompanion({
    this.word = const Value.absent(),
    this.langCode = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.phoneticUK = const Value.absent(),
    this.audioUs = const Value.absent(),
    this.audioUk = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.definition = const Value.absent(),
    this.definitionNative = const Value.absent(),
    this.example = const Value.absent(),
    this.romanization = const Value.absent(),
    this.source = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.isPhrase = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String word,
    required String langCode,
    this.phonetic = const Value.absent(),
    this.phoneticUK = const Value.absent(),
    this.audioUs = const Value.absent(),
    this.audioUk = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.definition = const Value.absent(),
    this.definitionNative = const Value.absent(),
    this.example = const Value.absent(),
    this.romanization = const Value.absent(),
    this.source = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.isPhrase = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       langCode = Value(langCode);
  static Insertable<Word> custom({
    Expression<String>? word,
    Expression<String>? langCode,
    Expression<String>? phonetic,
    Expression<String>? phoneticUK,
    Expression<String>? audioUs,
    Expression<String>? audioUk,
    Expression<String>? partOfSpeech,
    Expression<String>? definition,
    Expression<String>? definitionNative,
    Expression<String>? example,
    Expression<String>? romanization,
    Expression<String>? source,
    Expression<int>? cachedAt,
    Expression<String>? sourceType,
    Expression<String>? sourceContext,
    Expression<bool>? isPhrase,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (langCode != null) 'lang_code': langCode,
      if (phonetic != null) 'phonetic': phonetic,
      if (phoneticUK != null) 'phonetic_u_k': phoneticUK,
      if (audioUs != null) 'audio_us': audioUs,
      if (audioUk != null) 'audio_uk': audioUk,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (definition != null) 'definition': definition,
      if (definitionNative != null) 'definition_native': definitionNative,
      if (example != null) 'example': example,
      if (romanization != null) 'romanization': romanization,
      if (source != null) 'source': source,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceContext != null) 'source_context': sourceContext,
      if (isPhrase != null) 'is_phrase': isPhrase,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith({
    Value<String>? word,
    Value<String>? langCode,
    Value<String?>? phonetic,
    Value<String?>? phoneticUK,
    Value<String?>? audioUs,
    Value<String?>? audioUk,
    Value<String?>? partOfSpeech,
    Value<String?>? definition,
    Value<String?>? definitionNative,
    Value<String?>? example,
    Value<String?>? romanization,
    Value<String>? source,
    Value<int?>? cachedAt,
    Value<String?>? sourceType,
    Value<String?>? sourceContext,
    Value<bool>? isPhrase,
    Value<int>? rowid,
  }) {
    return WordsCompanion(
      word: word ?? this.word,
      langCode: langCode ?? this.langCode,
      phonetic: phonetic ?? this.phonetic,
      phoneticUK: phoneticUK ?? this.phoneticUK,
      audioUs: audioUs ?? this.audioUs,
      audioUk: audioUk ?? this.audioUk,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      definitionNative: definitionNative ?? this.definitionNative,
      example: example ?? this.example,
      romanization: romanization ?? this.romanization,
      source: source ?? this.source,
      cachedAt: cachedAt ?? this.cachedAt,
      sourceType: sourceType ?? this.sourceType,
      sourceContext: sourceContext ?? this.sourceContext,
      isPhrase: isPhrase ?? this.isPhrase,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (phoneticUK.present) {
      map['phonetic_u_k'] = Variable<String>(phoneticUK.value);
    }
    if (audioUs.present) {
      map['audio_us'] = Variable<String>(audioUs.value);
    }
    if (audioUk.present) {
      map['audio_uk'] = Variable<String>(audioUk.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (definitionNative.present) {
      map['definition_native'] = Variable<String>(definitionNative.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (romanization.present) {
      map['romanization'] = Variable<String>(romanization.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceContext.present) {
      map['source_context'] = Variable<String>(sourceContext.value);
    }
    if (isPhrase.present) {
      map['is_phrase'] = Variable<bool>(isPhrase.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('word: $word, ')
          ..write('langCode: $langCode, ')
          ..write('phonetic: $phonetic, ')
          ..write('phoneticUK: $phoneticUK, ')
          ..write('audioUs: $audioUs, ')
          ..write('audioUk: $audioUk, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('definition: $definition, ')
          ..write('definitionNative: $definitionNative, ')
          ..write('example: $example, ')
          ..write('romanization: $romanization, ')
          ..write('source: $source, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('isPhrase: $isPhrase, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordProgressTable extends WordProgress
    with TableInfo<$WordProgressTable, WordProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langCodeMeta = const VerificationMeta(
    'langCode',
  );
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
    'lang_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<int> nextReview = GeneratedColumn<int>(
    'next_review',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    word,
    langCode,
    status,
    reviewCount,
    correctCount,
    easeFactor,
    interval,
    nextReview,
    lastSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('lang_code')) {
      context.handle(
        _langCodeMeta,
        langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word, langCode};
  @override
  WordProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordProgressData(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      langCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang_code'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_review'],
      ),
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen'],
      ),
    );
  }

  @override
  $WordProgressTable createAlias(String alias) {
    return $WordProgressTable(attachedDatabase, alias);
  }
}

class WordProgressData extends DataClass
    implements Insertable<WordProgressData> {
  final String word;
  final String langCode;
  final String status;
  final int reviewCount;
  final int correctCount;
  final double easeFactor;
  final int interval;
  final int? nextReview;
  final int? lastSeen;
  const WordProgressData({
    required this.word,
    required this.langCode,
    required this.status,
    required this.reviewCount,
    required this.correctCount,
    required this.easeFactor,
    required this.interval,
    this.nextReview,
    this.lastSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['lang_code'] = Variable<String>(langCode);
    map['status'] = Variable<String>(status);
    map['review_count'] = Variable<int>(reviewCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval'] = Variable<int>(interval);
    if (!nullToAbsent || nextReview != null) {
      map['next_review'] = Variable<int>(nextReview);
    }
    if (!nullToAbsent || lastSeen != null) {
      map['last_seen'] = Variable<int>(lastSeen);
    }
    return map;
  }

  WordProgressCompanion toCompanion(bool nullToAbsent) {
    return WordProgressCompanion(
      word: Value(word),
      langCode: Value(langCode),
      status: Value(status),
      reviewCount: Value(reviewCount),
      correctCount: Value(correctCount),
      easeFactor: Value(easeFactor),
      interval: Value(interval),
      nextReview: nextReview == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReview),
      lastSeen: lastSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeen),
    );
  }

  factory WordProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordProgressData(
      word: serializer.fromJson<String>(json['word']),
      langCode: serializer.fromJson<String>(json['langCode']),
      status: serializer.fromJson<String>(json['status']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      interval: serializer.fromJson<int>(json['interval']),
      nextReview: serializer.fromJson<int?>(json['nextReview']),
      lastSeen: serializer.fromJson<int?>(json['lastSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'langCode': serializer.toJson<String>(langCode),
      'status': serializer.toJson<String>(status),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'interval': serializer.toJson<int>(interval),
      'nextReview': serializer.toJson<int?>(nextReview),
      'lastSeen': serializer.toJson<int?>(lastSeen),
    };
  }

  WordProgressData copyWith({
    String? word,
    String? langCode,
    String? status,
    int? reviewCount,
    int? correctCount,
    double? easeFactor,
    int? interval,
    Value<int?> nextReview = const Value.absent(),
    Value<int?> lastSeen = const Value.absent(),
  }) => WordProgressData(
    word: word ?? this.word,
    langCode: langCode ?? this.langCode,
    status: status ?? this.status,
    reviewCount: reviewCount ?? this.reviewCount,
    correctCount: correctCount ?? this.correctCount,
    easeFactor: easeFactor ?? this.easeFactor,
    interval: interval ?? this.interval,
    nextReview: nextReview.present ? nextReview.value : this.nextReview,
    lastSeen: lastSeen.present ? lastSeen.value : this.lastSeen,
  );
  WordProgressData copyWithCompanion(WordProgressCompanion data) {
    return WordProgressData(
      word: data.word.present ? data.word.value : this.word,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      status: data.status.present ? data.status.value : this.status,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      interval: data.interval.present ? data.interval.value : this.interval,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressData(')
          ..write('word: $word, ')
          ..write('langCode: $langCode, ')
          ..write('status: $status, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('nextReview: $nextReview, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    word,
    langCode,
    status,
    reviewCount,
    correctCount,
    easeFactor,
    interval,
    nextReview,
    lastSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordProgressData &&
          other.word == this.word &&
          other.langCode == this.langCode &&
          other.status == this.status &&
          other.reviewCount == this.reviewCount &&
          other.correctCount == this.correctCount &&
          other.easeFactor == this.easeFactor &&
          other.interval == this.interval &&
          other.nextReview == this.nextReview &&
          other.lastSeen == this.lastSeen);
}

class WordProgressCompanion extends UpdateCompanion<WordProgressData> {
  final Value<String> word;
  final Value<String> langCode;
  final Value<String> status;
  final Value<int> reviewCount;
  final Value<int> correctCount;
  final Value<double> easeFactor;
  final Value<int> interval;
  final Value<int?> nextReview;
  final Value<int?> lastSeen;
  final Value<int> rowid;
  const WordProgressCompanion({
    this.word = const Value.absent(),
    this.langCode = const Value.absent(),
    this.status = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordProgressCompanion.insert({
    required String word,
    required String langCode,
    this.status = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       langCode = Value(langCode);
  static Insertable<WordProgressData> custom({
    Expression<String>? word,
    Expression<String>? langCode,
    Expression<String>? status,
    Expression<int>? reviewCount,
    Expression<int>? correctCount,
    Expression<double>? easeFactor,
    Expression<int>? interval,
    Expression<int>? nextReview,
    Expression<int>? lastSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (langCode != null) 'lang_code': langCode,
      if (status != null) 'status': status,
      if (reviewCount != null) 'review_count': reviewCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (interval != null) 'interval': interval,
      if (nextReview != null) 'next_review': nextReview,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordProgressCompanion copyWith({
    Value<String>? word,
    Value<String>? langCode,
    Value<String>? status,
    Value<int>? reviewCount,
    Value<int>? correctCount,
    Value<double>? easeFactor,
    Value<int>? interval,
    Value<int?>? nextReview,
    Value<int?>? lastSeen,
    Value<int>? rowid,
  }) {
    return WordProgressCompanion(
      word: word ?? this.word,
      langCode: langCode ?? this.langCode,
      status: status ?? this.status,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReview: nextReview ?? this.nextReview,
      lastSeen: lastSeen ?? this.lastSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<int>(nextReview.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressCompanion(')
          ..write('word: $word, ')
          ..write('langCode: $langCode, ')
          ..write('status: $status, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('nextReview: $nextReview, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _langCodeMeta = const VerificationMeta(
    'langCode',
  );
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
    'lang_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordsStudiedMeta = const VerificationMeta(
    'wordsStudied',
  );
  @override
  late final GeneratedColumn<int> wordsStudied = GeneratedColumn<int>(
    'words_studied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordsKnownMeta = const VerificationMeta(
    'wordsKnown',
  );
  @override
  late final GeneratedColumn<int> wordsKnown = GeneratedColumn<int>(
    'words_known',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    langCode,
    startedAt,
    endedAt,
    wordsStudied,
    wordsKnown,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lang_code')) {
      context.handle(
        _langCodeMeta,
        langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('words_studied')) {
      context.handle(
        _wordsStudiedMeta,
        wordsStudied.isAcceptableOrUnknown(
          data['words_studied']!,
          _wordsStudiedMeta,
        ),
      );
    }
    if (data.containsKey('words_known')) {
      context.handle(
        _wordsKnownMeta,
        wordsKnown.isAcceptableOrUnknown(data['words_known']!, _wordsKnownMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      langCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang_code'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      wordsStudied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_studied'],
      )!,
      wordsKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_known'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String langCode;
  final int startedAt;
  final int? endedAt;
  final int wordsStudied;
  final int wordsKnown;
  const Session({
    required this.id,
    required this.langCode,
    required this.startedAt,
    this.endedAt,
    required this.wordsStudied,
    required this.wordsKnown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lang_code'] = Variable<String>(langCode);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['words_studied'] = Variable<int>(wordsStudied);
    map['words_known'] = Variable<int>(wordsKnown);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      langCode: Value(langCode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      wordsStudied: Value(wordsStudied),
      wordsKnown: Value(wordsKnown),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      langCode: serializer.fromJson<String>(json['langCode']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      wordsStudied: serializer.fromJson<int>(json['wordsStudied']),
      wordsKnown: serializer.fromJson<int>(json['wordsKnown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'langCode': serializer.toJson<String>(langCode),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'wordsStudied': serializer.toJson<int>(wordsStudied),
      'wordsKnown': serializer.toJson<int>(wordsKnown),
    };
  }

  Session copyWith({
    int? id,
    String? langCode,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    int? wordsStudied,
    int? wordsKnown,
  }) => Session(
    id: id ?? this.id,
    langCode: langCode ?? this.langCode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    wordsStudied: wordsStudied ?? this.wordsStudied,
    wordsKnown: wordsKnown ?? this.wordsKnown,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      wordsStudied: data.wordsStudied.present
          ? data.wordsStudied.value
          : this.wordsStudied,
      wordsKnown: data.wordsKnown.present
          ? data.wordsKnown.value
          : this.wordsKnown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('langCode: $langCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('wordsStudied: $wordsStudied, ')
          ..write('wordsKnown: $wordsKnown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, langCode, startedAt, endedAt, wordsStudied, wordsKnown);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.langCode == this.langCode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.wordsStudied == this.wordsStudied &&
          other.wordsKnown == this.wordsKnown);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> langCode;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> wordsStudied;
  final Value<int> wordsKnown;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.langCode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.wordsStudied = const Value.absent(),
    this.wordsKnown = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String langCode,
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.wordsStudied = const Value.absent(),
    this.wordsKnown = const Value.absent(),
  }) : langCode = Value(langCode),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? langCode,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? wordsStudied,
    Expression<int>? wordsKnown,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (langCode != null) 'lang_code': langCode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (wordsStudied != null) 'words_studied': wordsStudied,
      if (wordsKnown != null) 'words_known': wordsKnown,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? langCode,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<int>? wordsStudied,
    Value<int>? wordsKnown,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      langCode: langCode ?? this.langCode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      wordsStudied: wordsStudied ?? this.wordsStudied,
      wordsKnown: wordsKnown ?? this.wordsKnown,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (wordsStudied.present) {
      map['words_studied'] = Variable<int>(wordsStudied.value);
    }
    if (wordsKnown.present) {
      map['words_known'] = Variable<int>(wordsKnown.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('langCode: $langCode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('wordsStudied: $wordsStudied, ')
          ..write('wordsKnown: $wordsKnown')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordProgressTable wordProgress = $WordProgressTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final WordDao wordDao = WordDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    wordProgress,
    sessions,
  ];
}

typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      required String word,
      required String langCode,
      Value<String?> phonetic,
      Value<String?> phoneticUK,
      Value<String?> audioUs,
      Value<String?> audioUk,
      Value<String?> partOfSpeech,
      Value<String?> definition,
      Value<String?> definitionNative,
      Value<String?> example,
      Value<String?> romanization,
      Value<String> source,
      Value<int?> cachedAt,
      Value<String?> sourceType,
      Value<String?> sourceContext,
      Value<bool> isPhrase,
      Value<int> rowid,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<String> word,
      Value<String> langCode,
      Value<String?> phonetic,
      Value<String?> phoneticUK,
      Value<String?> audioUs,
      Value<String?> audioUk,
      Value<String?> partOfSpeech,
      Value<String?> definition,
      Value<String?> definitionNative,
      Value<String?> example,
      Value<String?> romanization,
      Value<String> source,
      Value<int?> cachedAt,
      Value<String?> sourceType,
      Value<String?> sourceContext,
      Value<bool> isPhrase,
      Value<int> rowid,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneticUK => $composableBuilder(
    column: $table.phoneticUK,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUs => $composableBuilder(
    column: $table.audioUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUk => $composableBuilder(
    column: $table.audioUk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionNative => $composableBuilder(
    column: $table.definitionNative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romanization => $composableBuilder(
    column: $table.romanization,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPhrase => $composableBuilder(
    column: $table.isPhrase,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneticUK => $composableBuilder(
    column: $table.phoneticUK,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUs => $composableBuilder(
    column: $table.audioUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUk => $composableBuilder(
    column: $table.audioUk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionNative => $composableBuilder(
    column: $table.definitionNative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romanization => $composableBuilder(
    column: $table.romanization,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPhrase => $composableBuilder(
    column: $table.isPhrase,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get phoneticUK => $composableBuilder(
    column: $table.phoneticUK,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUs =>
      $composableBuilder(column: $table.audioUs, builder: (column) => column);

  GeneratedColumn<String> get audioUk =>
      $composableBuilder(column: $table.audioUk, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionNative => $composableBuilder(
    column: $table.definitionNative,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get romanization => $composableBuilder(
    column: $table.romanization,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPhrase =>
      $composableBuilder(column: $table.isPhrase, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
          Word,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> langCode = const Value.absent(),
                Value<String?> phonetic = const Value.absent(),
                Value<String?> phoneticUK = const Value.absent(),
                Value<String?> audioUs = const Value.absent(),
                Value<String?> audioUk = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> definition = const Value.absent(),
                Value<String?> definitionNative = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> romanization = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> cachedAt = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<bool> isPhrase = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion(
                word: word,
                langCode: langCode,
                phonetic: phonetic,
                phoneticUK: phoneticUK,
                audioUs: audioUs,
                audioUk: audioUk,
                partOfSpeech: partOfSpeech,
                definition: definition,
                definitionNative: definitionNative,
                example: example,
                romanization: romanization,
                source: source,
                cachedAt: cachedAt,
                sourceType: sourceType,
                sourceContext: sourceContext,
                isPhrase: isPhrase,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                required String langCode,
                Value<String?> phonetic = const Value.absent(),
                Value<String?> phoneticUK = const Value.absent(),
                Value<String?> audioUs = const Value.absent(),
                Value<String?> audioUk = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> definition = const Value.absent(),
                Value<String?> definitionNative = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> romanization = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> cachedAt = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<bool> isPhrase = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion.insert(
                word: word,
                langCode: langCode,
                phonetic: phonetic,
                phoneticUK: phoneticUK,
                audioUs: audioUs,
                audioUk: audioUk,
                partOfSpeech: partOfSpeech,
                definition: definition,
                definitionNative: definitionNative,
                example: example,
                romanization: romanization,
                source: source,
                cachedAt: cachedAt,
                sourceType: sourceType,
                sourceContext: sourceContext,
                isPhrase: isPhrase,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
      Word,
      PrefetchHooks Function()
    >;
typedef $$WordProgressTableCreateCompanionBuilder =
    WordProgressCompanion Function({
      required String word,
      required String langCode,
      Value<String> status,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int?> nextReview,
      Value<int?> lastSeen,
      Value<int> rowid,
    });
typedef $$WordProgressTableUpdateCompanionBuilder =
    WordProgressCompanion Function({
      Value<String> word,
      Value<String> langCode,
      Value<String> status,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int?> nextReview,
      Value<int?> lastSeen,
      Value<int> rowid,
    });

class $$WordProgressTableFilterComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);
}

class $$WordProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordProgressTable,
          WordProgressData,
          $$WordProgressTableFilterComposer,
          $$WordProgressTableOrderingComposer,
          $$WordProgressTableAnnotationComposer,
          $$WordProgressTableCreateCompanionBuilder,
          $$WordProgressTableUpdateCompanionBuilder,
          (
            WordProgressData,
            BaseReferences<_$AppDatabase, $WordProgressTable, WordProgressData>,
          ),
          WordProgressData,
          PrefetchHooks Function()
        > {
  $$WordProgressTableTableManager(_$AppDatabase db, $WordProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> langCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int?> nextReview = const Value.absent(),
                Value<int?> lastSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion(
                word: word,
                langCode: langCode,
                status: status,
                reviewCount: reviewCount,
                correctCount: correctCount,
                easeFactor: easeFactor,
                interval: interval,
                nextReview: nextReview,
                lastSeen: lastSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                required String langCode,
                Value<String> status = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int?> nextReview = const Value.absent(),
                Value<int?> lastSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion.insert(
                word: word,
                langCode: langCode,
                status: status,
                reviewCount: reviewCount,
                correctCount: correctCount,
                easeFactor: easeFactor,
                interval: interval,
                nextReview: nextReview,
                lastSeen: lastSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordProgressTable,
      WordProgressData,
      $$WordProgressTableFilterComposer,
      $$WordProgressTableOrderingComposer,
      $$WordProgressTableAnnotationComposer,
      $$WordProgressTableCreateCompanionBuilder,
      $$WordProgressTableUpdateCompanionBuilder,
      (
        WordProgressData,
        BaseReferences<_$AppDatabase, $WordProgressTable, WordProgressData>,
      ),
      WordProgressData,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String langCode,
      required int startedAt,
      Value<int?> endedAt,
      Value<int> wordsStudied,
      Value<int> wordsKnown,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> langCode,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<int> wordsStudied,
      Value<int> wordsKnown,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsStudied => $composableBuilder(
    column: $table.wordsStudied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsKnown => $composableBuilder(
    column: $table.wordsKnown,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsStudied => $composableBuilder(
    column: $table.wordsStudied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsKnown => $composableBuilder(
    column: $table.wordsKnown,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get wordsStudied => $composableBuilder(
    column: $table.wordsStudied,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordsKnown => $composableBuilder(
    column: $table.wordsKnown,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> langCode = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> wordsStudied = const Value.absent(),
                Value<int> wordsKnown = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                langCode: langCode,
                startedAt: startedAt,
                endedAt: endedAt,
                wordsStudied: wordsStudied,
                wordsKnown: wordsKnown,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String langCode,
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                Value<int> wordsStudied = const Value.absent(),
                Value<int> wordsKnown = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                langCode: langCode,
                startedAt: startedAt,
                endedAt: endedAt,
                wordsStudied: wordsStudied,
                wordsKnown: wordsKnown,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordProgressTableTableManager get wordProgress =>
      $$WordProgressTableTableManager(_db, _db.wordProgress);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
}
