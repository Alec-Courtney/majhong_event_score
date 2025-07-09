// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  name: json['队员'] as String,
  mahjongId: json['雀魂ID'] as String?,
  team: json['队伍'] as String,
  score: (json['score'] as num?)?.toDouble() ?? 0.0,
  gamesPlayed: (json['半庄数'] as num?)?.toInt() ?? 0,
  rank1: (json['1位'] as num?)?.toInt() ?? 0,
  rank2: (json['2位'] as num?)?.toInt() ?? 0,
  rank3: (json['3位'] as num?)?.toInt() ?? 0,
  rank4: (json['4位'] as num?)?.toInt() ?? 0,
  highestScore: (json['最高得点'] as num?)?.toInt() ?? 0,
  avoidFourthRate: (json['避四率'] as num?)?.toDouble() ?? 0.0,
  consecutiveWinRate: (json['连对率'] as num?)?.toDouble() ?? 0.0,
  averageRank: (json['平均顺位'] as num?)?.toDouble() ?? 0.0,
  averageGameScore: (json['平均场分'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  '队员': instance.name,
  '雀魂ID': instance.mahjongId,
  '队伍': instance.team,
  'score': instance.score,
  '半庄数': instance.gamesPlayed,
  '1位': instance.rank1,
  '2位': instance.rank2,
  '3位': instance.rank3,
  '4位': instance.rank4,
  '最高得点': instance.highestScore,
  '避四率': instance.avoidFourthRate,
  '连对率': instance.consecutiveWinRate,
  '平均顺位': instance.averageRank,
  '平均场分': instance.averageGameScore,
};
