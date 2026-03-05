// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  name: json['name'] as String,
  score: (json['score'] as num?)?.toDouble() ?? 0.0,
  scoreDifference: (json['scoreDifference'] as num?)?.toDouble() ?? 0.0,
  gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
  rank1: (json['rank1'] as num?)?.toInt() ?? 0,
  rank2: (json['rank2'] as num?)?.toInt() ?? 0,
  rank3: (json['rank3'] as num?)?.toInt() ?? 0,
  rank4: (json['rank4'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'name': instance.name,
  'score': instance.score,
  'scoreDifference': instance.scoreDifference,
  'gamesPlayed': instance.gamesPlayed,
  'rank1': instance.rank1,
  'rank2': instance.rank2,
  'rank3': instance.rank3,
  'rank4': instance.rank4,
};
