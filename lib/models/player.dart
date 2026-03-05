import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable()
class Player {
  @JsonKey(name: '队员')
  final String name;
  @JsonKey(name: '雀魂ID')
  final String? mahjongId;
  @JsonKey(name: '队伍')
  final String team;

  /// 统计数据，初始化为0或默认值
  double score;
  @JsonKey(name: '半庄数')
  int gamesPlayed;
  @JsonKey(name: '1位')
  int rank1;
  @JsonKey(name: '2位')
  int rank2;
  @JsonKey(name: '3位')
  int rank3;
  @JsonKey(name: '4位')
  int rank4;
  @JsonKey(name: '最高得点')
  int highestScore;
  @JsonKey(name: '避四率')
  double avoidFourthRate;
  @JsonKey(name: '连对率')
  double consecutiveWinRate;
  @JsonKey(name: '平均顺位')
  double averageRank;
  @JsonKey(name: '平均场分')
  double averageGameScore;

  Player({
    required this.name,
    this.mahjongId,
    required this.team,
    this.score = 0.0,
    this.gamesPlayed = 0,
    this.rank1 = 0,
    this.rank2 = 0,
    this.rank3 = 0,
    this.rank4 = 0,
    this.highestScore = 0,
    this.avoidFourthRate = 0.0,
    this.consecutiveWinRate = 0.0,
    this.averageRank = 0.0,
    this.averageGameScore = 0.0,
  });

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  /// 用于重置统计数据的方法
  void resetStats() {
    score = 0.0;
    gamesPlayed = 0;
    rank1 = 0;
    rank2 = 0;
    rank3 = 0;
    rank4 = 0;
    highestScore = 0;
    avoidFourthRate = 0.0;
    consecutiveWinRate = 0.0;
    averageRank = 0.0;
    averageGameScore = 0.0;
  }
}
