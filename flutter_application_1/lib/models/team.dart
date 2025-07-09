import 'package:json_annotation/json_annotation.dart';

part 'team.g.dart';

@JsonSerializable()
class Team {
  final String name;
  double score;
  double scoreDifference;
  int gamesPlayed;
  int rank1;
  int rank2;
  int rank3;
  int rank4;

  Team({
    required this.name,
    this.score = 0.0,
    this.scoreDifference = 0.0,
    this.gamesPlayed = 0,
    this.rank1 = 0,
    this.rank2 = 0,
    this.rank3 = 0,
    this.rank4 = 0,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}
