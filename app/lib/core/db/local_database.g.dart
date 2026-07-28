// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $PendingWritesTable extends PendingWrites
    with TableInfo<$PendingWritesTable, PendingWrite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingWritesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    endpoint,
    payload,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_writes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingWrite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingWrite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingWrite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingWritesTable createAlias(String alias) {
    return $PendingWritesTable(attachedDatabase, alias);
  }
}

class PendingWrite extends DataClass implements Insertable<PendingWrite> {
  final int id;

  /// Caminho relativo, ex.: `/api/sessions`.
  final String endpoint;
  final String payload;
  final DateTime createdAt;
  final int attempts;

  /// Motivo da última falha — só para diagnóstico; não decide nada.
  final String? lastError;
  const PendingWrite({
    required this.id,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['endpoint'] = Variable<String>(endpoint);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingWritesCompanion toCompanion(bool nullToAbsent) {
    return PendingWritesCompanion(
      id: Value(id),
      endpoint: Value(endpoint),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingWrite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingWrite(
      id: serializer.fromJson<int>(json['id']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'endpoint': serializer.toJson<String>(endpoint),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingWrite copyWith({
    int? id,
    String? endpoint,
    String? payload,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => PendingWrite(
    id: id ?? this.id,
    endpoint: endpoint ?? this.endpoint,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingWrite copyWithCompanion(PendingWritesCompanion data) {
    return PendingWrite(
      id: data.id.present ? data.id.value : this.id,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingWrite(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, endpoint, payload, createdAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingWrite &&
          other.id == this.id &&
          other.endpoint == this.endpoint &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class PendingWritesCompanion extends UpdateCompanion<PendingWrite> {
  final Value<int> id;
  final Value<String> endpoint;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const PendingWritesCompanion({
    this.id = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingWritesCompanion.insert({
    this.id = const Value.absent(),
    required String endpoint,
    required String payload,
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : endpoint = Value(endpoint),
       payload = Value(payload);
  static Insertable<PendingWrite> custom({
    Expression<int>? id,
    Expression<String>? endpoint,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endpoint != null) 'endpoint': endpoint,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingWritesCompanion copyWith({
    Value<int>? id,
    Value<String>? endpoint,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return PendingWritesCompanion(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingWritesCompanion(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $CachedExercisesTable extends CachedExercises
    with TableInfo<$CachedExercisesTable, CachedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleGroupMeta = const VerificationMeta(
    'muscleGroup',
  );
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
    'muscle_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompoundMeta = const VerificationMeta(
    'isCompound',
  );
  @override
  late final GeneratedColumn<bool> isCompound = GeneratedColumn<bool>(
    'is_compound',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_compound" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    muscleGroup,
    equipment,
    isCompound,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
        _muscleGroupMeta,
        muscleGroup.isAcceptableOrUnknown(
          data['muscle_group']!,
          _muscleGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_muscleGroupMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('is_compound')) {
      context.handle(
        _isCompoundMeta,
        isCompound.isAcceptableOrUnknown(data['is_compound']!, _isCompoundMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      muscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_group'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      isCompound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_compound'],
      )!,
    );
  }

  @override
  $CachedExercisesTable createAlias(String alias) {
    return $CachedExercisesTable(attachedDatabase, alias);
  }
}

class CachedExercise extends DataClass implements Insertable<CachedExercise> {
  final int id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final bool isCompound;
  const CachedExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.isCompound,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['muscle_group'] = Variable<String>(muscleGroup);
    map['equipment'] = Variable<String>(equipment);
    map['is_compound'] = Variable<bool>(isCompound);
    return map;
  }

  CachedExercisesCompanion toCompanion(bool nullToAbsent) {
    return CachedExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleGroup: Value(muscleGroup),
      equipment: Value(equipment),
      isCompound: Value(isCompound),
    );
  }

  factory CachedExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleGroup: serializer.fromJson<String>(json['muscleGroup']),
      equipment: serializer.fromJson<String>(json['equipment']),
      isCompound: serializer.fromJson<bool>(json['isCompound']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'muscleGroup': serializer.toJson<String>(muscleGroup),
      'equipment': serializer.toJson<String>(equipment),
      'isCompound': serializer.toJson<bool>(isCompound),
    };
  }

  CachedExercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
    String? equipment,
    bool? isCompound,
  }) => CachedExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    equipment: equipment ?? this.equipment,
    isCompound: isCompound ?? this.isCompound,
  );
  CachedExercise copyWithCompanion(CachedExercisesCompanion data) {
    return CachedExercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      isCompound: data.isCompound.present
          ? data.isCompound.value
          : this.isCompound,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('isCompound: $isCompound')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, muscleGroup, equipment, isCompound);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleGroup == this.muscleGroup &&
          other.equipment == this.equipment &&
          other.isCompound == this.isCompound);
}

class CachedExercisesCompanion extends UpdateCompanion<CachedExercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> muscleGroup;
  final Value<String> equipment;
  final Value<bool> isCompound;
  const CachedExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.equipment = const Value.absent(),
    this.isCompound = const Value.absent(),
  });
  CachedExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String muscleGroup,
    required String equipment,
    this.isCompound = const Value.absent(),
  }) : name = Value(name),
       muscleGroup = Value(muscleGroup),
       equipment = Value(equipment);
  static Insertable<CachedExercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? muscleGroup,
    Expression<String>? equipment,
    Expression<bool>? isCompound,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (equipment != null) 'equipment': equipment,
      if (isCompound != null) 'is_compound': isCompound,
    });
  }

  CachedExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? muscleGroup,
    Value<String>? equipment,
    Value<bool>? isCompound,
  }) {
    return CachedExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      isCompound: isCompound ?? this.isCompound,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (isCompound.present) {
      map['is_compound'] = Variable<bool>(isCompound.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('isCompound: $isCompound')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $PendingWritesTable pendingWrites = $PendingWritesTable(this);
  late final $CachedExercisesTable cachedExercises = $CachedExercisesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingWrites,
    cachedExercises,
  ];
}

typedef $$PendingWritesTableCreateCompanionBuilder =
    PendingWritesCompanion Function({
      Value<int> id,
      required String endpoint,
      required String payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$PendingWritesTableUpdateCompanionBuilder =
    PendingWritesCompanion Function({
      Value<int> id,
      Value<String> endpoint,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$PendingWritesTableFilterComposer
    extends Composer<_$LocalDatabase, $PendingWritesTable> {
  $$PendingWritesTableFilterComposer({
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

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingWritesTableOrderingComposer
    extends Composer<_$LocalDatabase, $PendingWritesTable> {
  $$PendingWritesTableOrderingComposer({
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

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingWritesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PendingWritesTable> {
  $$PendingWritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingWritesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PendingWritesTable,
          PendingWrite,
          $$PendingWritesTableFilterComposer,
          $$PendingWritesTableOrderingComposer,
          $$PendingWritesTableAnnotationComposer,
          $$PendingWritesTableCreateCompanionBuilder,
          $$PendingWritesTableUpdateCompanionBuilder,
          (
            PendingWrite,
            BaseReferences<_$LocalDatabase, $PendingWritesTable, PendingWrite>,
          ),
          PendingWrite,
          PrefetchHooks Function()
        > {
  $$PendingWritesTableTableManager(
    _$LocalDatabase db,
    $PendingWritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingWritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingWritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingWritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingWritesCompanion(
                id: id,
                endpoint: endpoint,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String endpoint,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingWritesCompanion.insert(
                id: id,
                endpoint: endpoint,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingWritesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PendingWritesTable,
      PendingWrite,
      $$PendingWritesTableFilterComposer,
      $$PendingWritesTableOrderingComposer,
      $$PendingWritesTableAnnotationComposer,
      $$PendingWritesTableCreateCompanionBuilder,
      $$PendingWritesTableUpdateCompanionBuilder,
      (
        PendingWrite,
        BaseReferences<_$LocalDatabase, $PendingWritesTable, PendingWrite>,
      ),
      PendingWrite,
      PrefetchHooks Function()
    >;
typedef $$CachedExercisesTableCreateCompanionBuilder =
    CachedExercisesCompanion Function({
      Value<int> id,
      required String name,
      required String muscleGroup,
      required String equipment,
      Value<bool> isCompound,
    });
typedef $$CachedExercisesTableUpdateCompanionBuilder =
    CachedExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> muscleGroup,
      Value<String> equipment,
      Value<bool> isCompound,
    });

class $$CachedExercisesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompound => $composableBuilder(
    column: $table.isCompound,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExercisesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompound => $composableBuilder(
    column: $table.isCompound,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExercisesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<bool> get isCompound => $composableBuilder(
    column: $table.isCompound,
    builder: (column) => column,
  );
}

class $$CachedExercisesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedExercisesTable,
          CachedExercise,
          $$CachedExercisesTableFilterComposer,
          $$CachedExercisesTableOrderingComposer,
          $$CachedExercisesTableAnnotationComposer,
          $$CachedExercisesTableCreateCompanionBuilder,
          $$CachedExercisesTableUpdateCompanionBuilder,
          (
            CachedExercise,
            BaseReferences<
              _$LocalDatabase,
              $CachedExercisesTable,
              CachedExercise
            >,
          ),
          CachedExercise,
          PrefetchHooks Function()
        > {
  $$CachedExercisesTableTableManager(
    _$LocalDatabase db,
    $CachedExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> muscleGroup = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<bool> isCompound = const Value.absent(),
              }) => CachedExercisesCompanion(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                isCompound: isCompound,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String muscleGroup,
                required String equipment,
                Value<bool> isCompound = const Value.absent(),
              }) => CachedExercisesCompanion.insert(
                id: id,
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                isCompound: isCompound,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedExercisesTable,
      CachedExercise,
      $$CachedExercisesTableFilterComposer,
      $$CachedExercisesTableOrderingComposer,
      $$CachedExercisesTableAnnotationComposer,
      $$CachedExercisesTableCreateCompanionBuilder,
      $$CachedExercisesTableUpdateCompanionBuilder,
      (
        CachedExercise,
        BaseReferences<_$LocalDatabase, $CachedExercisesTable, CachedExercise>,
      ),
      CachedExercise,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$PendingWritesTableTableManager get pendingWrites =>
      $$PendingWritesTableTableManager(_db, _db.pendingWrites);
  $$CachedExercisesTableTableManager get cachedExercises =>
      $$CachedExercisesTableTableManager(_db, _db.cachedExercises);
}
