// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals

extension GetWordModelCollection on Isar {
  IsarCollection<WordModel> get wordModels => this.collection();
}

const WordModelSchema = CollectionSchema(
  name: r'WordModel',
  id: 1779268377755835928,
  properties: {
    r'correctCount': PropertySchema(
      id: 0,
      name: r'correctCount',
      type: IsarType.long,
    ),
    r'examples': PropertySchema(
      id: 1,
      name: r'examples',
      type: IsarType.stringList,
    ),
    r'level': PropertySchema(
      id: 2,
      name: r'level',
      type: IsarType.string,
    ),
    r'libraryName': PropertySchema(
      id: 3,
      name: r'libraryName',
      type: IsarType.string,
    ),
    r'listType': PropertySchema(
      id: 4,
      name: r'listType',
      type: IsarType.string,
    ),
    r'meanings': PropertySchema(
      id: 5,
      name: r'meanings',
      type: IsarType.stringList,
    ),
    r'nextReviewDate': PropertySchema(
      id: 6,
      name: r'nextReviewDate',
      type: IsarType.long,
    ),
    r'srsLevel': PropertySchema(
      id: 7,
      name: r'srsLevel',
      type: IsarType.long,
    ),
    r'word': PropertySchema(
      id: 8,
      name: r'word',
      type: IsarType.string,
    ),
    r'wrongCount': PropertySchema(
      id: 9,
      name: r'wrongCount',
      type: IsarType.long,
    ),
  },
  estimateSize: _wordModelEstimateSize,
  serialize: _wordModelSerialize,
  deserialize: _wordModelDeserialize,
  deserializeProp: _wordModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'word': IndexSpec(
      element: [
        IndexType.hash,
      ],
      caseSensitive: true,
    ),
    r'libraryName': IndexSpec(
      element: [
        IndexType.hash,
      ],
      caseSensitive: true,
    ),
    r'level': IndexSpec(
      element: [
        IndexType.hash,
      ],
      caseSensitive: true,
    ),
    r'correctCount': IndexSpec(
      element: [
        IndexType.value,
      ],
      caseSensitive: false,
    ),
    r'wrongCount': IndexSpec(
      element: [
        IndexType.value,
      ],
      caseSensitive: false,
    ),
    r'listType': IndexSpec(
      element: [
        IndexType.hash,
      ],
      caseSensitive: true,
    ),
    r'srsLevel': IndexSpec(
      element: [
        IndexType.value,
      ],
      caseSensitive: false,
    ),
    r'nextReviewDate': IndexSpec(
      element: [
        IndexType.value,
      ],
      caseSensitive: false,
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _wordModelGetId,
  setId: _wordModelSetId,
  getLinkedObjects: _wordModelGetLinkedObjects,
  createSyncedLinks: _wordModelCreateSyncedLinks,
  retryOnConflict: false,
);

int _wordModelEstimateSize(
  WordModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.examples.fold(0, (p, e) => p + e.length) * 3;
  bytesCount += 3 + object.level.length * 3;
  bytesCount += 3 + object.libraryName.length * 3;
  bytesCount += 3 + object.listType.length * 3;
  bytesCount += 3 + object.meanings.fold(0, (p, e) => p + e.length) * 3;
  bytesCount += 3 + object.word.length * 3;
  return bytesCount;
}

void _wordModelSerialize(
  WordModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.correctCount);
  writer.writeStringList(offsets[1], object.examples);
  writer.writeString(offsets[2], object.level);
  writer.writeString(offsets[3], object.libraryName);
  writer.writeString(offsets[4], object.listType);
  writer.writeStringList(offsets[5], object.meanings);
  writer.writeLong(offsets[6], object.nextReviewDate);
  writer.writeLong(offsets[7], object.srsLevel);
  writer.writeString(offsets[8], object.word);
  writer.writeLong(offsets[9], object.wrongCount);
}

WordModel _wordModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WordModel(
    examples: reader.readStringList(offsets[1]) ?? [],
    level: reader.readString(offsets[2]) ?? '',
    libraryName: reader.readString(offsets[3]) ?? '',
    listType: reader.readString(offsets[4]) ?? '',
    meanings: reader.readStringList(offsets[5]) ?? [],
    word: reader.readString(offsets[8]) ?? '',
  );
  object.correctCount = reader.readLong(offsets[0]);
  object.id = id;
  object.nextReviewDate = reader.readLong(offsets[6]);
  object.srsLevel = reader.readLong(offsets[7]);
  object.wrongCount = reader.readLong(offsets[9]);
  return object;
}

P _wordModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readString(offset) ?? '') as P;
    case 3:
      return (reader.readString(offset) ?? '') as P;
    case 4:
      return (reader.readString(offset) ?? '') as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset) ?? '') as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw 'Unknown property $propertyId';
  }
}

Id _wordModelGetId(WordModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _wordModelGetLinkedObjects(WordModel object) {
  return [];
}

void _wordModelSetId(WordModel object, Id id) {
  object.id = id;
}

List<IsarInterceptor<WordModel>> _wordModelCreateSyncedLinks(WordModel object) {
  return [];
}

extension WordModelQueryWhereSort
    on QueryBuilder<WordModel, WordModel, QWhere> {
  QueryBuilder<WordModel, WordModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WordModelQueryWhere
    on QueryBuilder<WordModel, WordModel, QWhereClause> {
  QueryBuilder<WordModel, WordModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool includeLower = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: includeLower),
      );
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> idLessThan(Id id,
      {bool includeUpper = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        upper: upperId,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wordEqualTo(
      String word) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'word',
        value: [word],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wordNotEqualTo(
      String word) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'word',
              lower: [],
              upper: [word],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'word',
              lower: [word],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'word',
              lower: [word],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'word',
              lower: [],
              upper: [word],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> libraryNameEqualTo(
      String libraryName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'libraryName',
        value: [libraryName],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> libraryNameNotEqualTo(
      String libraryName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'libraryName',
              lower: [],
              upper: [libraryName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'libraryName',
              lower: [libraryName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'libraryName',
              lower: [libraryName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'libraryName',
              lower: [],
              upper: [libraryName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> levelEqualTo(
      String level) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'level',
        value: [level],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> levelNotEqualTo(
      String level) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'level',
              lower: [],
              upper: [level],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'level',
              lower: [level],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'level',
              lower: [level],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'level',
              lower: [],
              upper: [level],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> correctCountEqualTo(
      int correctCount) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'correctCount',
        value: [correctCount],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> correctCountNotEqualTo(
      int correctCount) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'correctCount',
              lower: [],
              upper: [correctCount],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'correctCount',
              lower: [correctCount],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'correctCount',
              lower: [correctCount],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'correctCount',
              lower: [],
              upper: [correctCount],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> correctCountGreaterThan(
    int correctCount, {
    bool includeLower = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'correctCount',
        lower: [correctCount],
        includeLower: includeLower,
        upper: [],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> correctCountLessThan(
    int correctCount, {
    bool includeUpper = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'correctCount',
        lower: [],
        upper: [correctCount],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> correctCountBetween(
    int lowerCorrectCount,
    int upperCorrectCount, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'correctCount',
        lower: [lowerCorrectCount],
        includeLower: includeLower,
        upper: [upperCorrectCount],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wrongCountEqualTo(
      int wrongCount) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'wrongCount',
        value: [wrongCount],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wrongCountNotEqualTo(
      int wrongCount) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'wrongCount',
              lower: [],
              upper: [wrongCount],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'wrongCount',
              lower: [wrongCount],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'wrongCount',
              lower: [wrongCount],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'wrongCount',
              lower: [],
              upper: [wrongCount],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wrongCountGreaterThan(
    int wrongCount, {
    bool includeLower = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'wrongCount',
        lower: [wrongCount],
        includeLower: includeLower,
        upper: [],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wrongCountLessThan(
    int wrongCount, {
    bool includeUpper = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'wrongCount',
        lower: [],
        upper: [wrongCount],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> wrongCountBetween(
    int lowerWrongCount,
    int upperWrongCount, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'wrongCount',
        lower: [lowerWrongCount],
        includeLower: includeLower,
        upper: [upperWrongCount],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> listTypeEqualTo(
      String listType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'listType',
        value: [listType],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> listTypeNotEqualTo(
      String listType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listType',
              lower: [],
              upper: [listType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listType',
              lower: [listType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listType',
              lower: [listType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listType',
              lower: [],
              upper: [listType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> srsLevelEqualTo(
      int srsLevel) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'srsLevel',
        value: [srsLevel],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> srsLevelNotEqualTo(
      int srsLevel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'srsLevel',
              lower: [],
              upper: [srsLevel],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'srsLevel',
              lower: [srsLevel],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'srsLevel',
              lower: [srsLevel],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'srsLevel',
              lower: [],
              upper: [srsLevel],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> srsLevelGreaterThan(
    int srsLevel, {
    bool includeLower = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'srsLevel',
        lower: [srsLevel],
        includeLower: includeLower,
        upper: [],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> srsLevelLessThan(
    int srsLevel, {
    bool includeUpper = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'srsLevel',
        lower: [],
        upper: [srsLevel],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> srsLevelBetween(
    int lowerSrsLevel,
    int upperSrsLevel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'srsLevel',
        lower: [lowerSrsLevel],
        includeLower: includeLower,
        upper: [upperSrsLevel],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> nextReviewDateEqualTo(
      int nextReviewDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nextReviewDate',
        value: [nextReviewDate],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause>
      nextReviewDateNotEqualTo(int nextReviewDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextReviewDate',
              lower: [],
              upper: [nextReviewDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextReviewDate',
              lower: [nextReviewDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextReviewDate',
              lower: [nextReviewDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextReviewDate',
              lower: [],
              upper: [nextReviewDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause>
      nextReviewDateGreaterThan(
    int nextReviewDate, {
    bool includeLower = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextReviewDate',
        lower: [nextReviewDate],
        includeLower: includeLower,
        upper: [],
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> nextReviewDateLessThan(
    int nextReviewDate, {
    bool includeUpper = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextReviewDate',
        lower: [],
        upper: [nextReviewDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterWhereClause> nextReviewDateBetween(
    int lowerNextReviewDate,
    int upperNextReviewDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextReviewDate',
        lower: [lowerNextReviewDate],
        includeLower: includeLower,
        upper: [upperNextReviewDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WordModelQueryFilter
    on QueryBuilder<WordModel, WordModel, QFilterCondition> {
  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> correctCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      correctCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> correctCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> correctCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctCount',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      examplesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'examples',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'examples',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesElementMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'examples',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> examplesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isEmpty(
        property: r'examples',
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      examplesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotEmpty(
        property: r'examples',
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelNotEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.notEqualTo(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'level',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> levelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'level',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      libraryNameNotEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.notEqualTo(
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      libraryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'libraryName',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      libraryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'libraryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> libraryNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'libraryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeNotEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.notEqualTo(
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listType',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> listTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'meanings',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'meanings',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'meanings',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> meaningsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isEmpty(
        property: r'meanings',
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      meaningsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotEmpty(
        property: r'meanings',
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      nextReviewDateEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      nextReviewDateGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      nextReviewDateLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      nextReviewDateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextReviewDate',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> srsLevelEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'srsLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      srsLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'srsLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> srsLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'srsLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> srsLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'srsLevel',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordNotEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.notEqualTo(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'word',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'word',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'word',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wrongCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition>
      wrongCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wrongCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wrongCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wrongCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wrongCount',
        lower: lower,
        upper: upper,
        includeLower: includeLower,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WordModelQueryObject
    on QueryBuilder<WordModel, WordModel, QFilterCondition> {}

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'word',
      ));
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterFilterCondition> wordIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'word',
      ));
    });
  }

extension WordModelQueryLinks
    on QueryBuilder<WordModel, WordModel, QFilterCondition> {}

extension WordModelQuerySortBy on QueryBuilder<WordModel, WordModel, QSortBy> {
  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByCorrectCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByLibraryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'libraryName', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByLibraryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'libraryName', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortToListType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listType', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortToListTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listType', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortBySrsLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srsLevel', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortBySrsLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srsLevel', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> sortByWrongCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.desc);
    });
  }
}

extension WordModelQuerySortThenBy
    on QueryBuilder<WordModel, WordModel, QSortThenBy> {
  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByCorrectCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctCount', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByLibraryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'libraryName', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByLibraryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'libraryName', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByListType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listType', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByListTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listType', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenBySrsLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srsLevel', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenBySrsLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srsLevel', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'word', Sort.desc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.asc);
    });
  }

  QueryBuilder<WordModel, WordModel, QAfterSortBy> thenByWrongCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongCount', Sort.desc);
    });
  }
}

extension WordModelQueryWhereDistinct
    on QueryBuilder<WordModel, WordModel, QDistinct> {
  QueryBuilder<WordModel, WordModel, QDistinct> distinctByCorrectCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctCount');
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByLevel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByLibraryName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'libraryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByListType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctBySrsLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'srsLevel');
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByWord(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'word', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WordModel, WordModel, QDistinct> distinctByWrongCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wrongCount');
    });
  }
}

extension WordModelQueryProperty
    on QueryBuilder<WordModel, WordModel, QQueryProperty> {
  QueryBuilder<WordModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WordModel, int, QQueryOperations> correctCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctCount');
    });
  }

  QueryBuilder<WordModel, List<String>, QQueryOperations> examplesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'examples');
    });
  }

  QueryBuilder<WordModel, String, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<WordModel, String, QQueryOperations> libraryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'libraryName');
    });
  }

  QueryBuilder<WordModel, String, QQueryOperations> listTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addPropertyName', r'listType');
    });
  }

  QueryBuilder<WordModel, List<String>, QQueryOperations> meaningsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meanings');
    });
  }

  QueryBuilder<WordModel, List<String>, QQueryOperations> nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<WordModel, int, QQueryOperations> srsLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'srsLevel');
    });
  }

  QueryBuilder<WordModel, String, QQueryOperations> wordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'word');
    });
  }

  QueryBuilder<WordModel, int, QQueryOperations> wrongCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wrongCount');
    });
  }
}
