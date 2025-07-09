import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../models/player.dart';
import '../models/event.dart';
import '../models/game_log.dart'; // Import GameLogEntry and GameResult
import '../models/team.dart'; // Import Team model

class AnalysisWindow extends StatefulWidget {
  final Event currentEvent;
  final List<Player> playerDf;
  final Map<String, Color> teamColorMap;

  const AnalysisWindow({
    super.key,
    required this.currentEvent,
    required this.playerDf,
    required this.teamColorMap,
  });

  @override
  State<AnalysisWindow> createState() => _AnalysisWindowState();
}

class _AnalysisWindowState extends State<AnalysisWindow> {
  String? _selectedChartType; // 'player', 'team', 'all_teams'
  String? _selectedEntityName; // Player name or Team name

  @override
  void initState() {
    super.initState();
    // Initialize with the first player or a default if no players
    if (widget.playerDf.isNotEmpty) {
      _selectedChartType = 'player';
      _selectedEntityName = widget.playerDf.first.name;
    } else if (widget.currentEvent.isTeamEvent) {
      _selectedChartType = 'all_teams';
      _selectedEntityName = '所有队伍总分';
    }
  }

  // Helper to get all unique team names
  List<String> _getAllTeamNames() {
    return widget.currentEvent.playerBaseData.map((p) => p.team).toSet().toList();
  }

  // Calculates score trend for a single player
  List<FlSpot> _getPlayerScoreTrendLineData(String playerName) {
    Player? player = widget.currentEvent.playerBaseData.firstWhereOrNull((p) => p.name == playerName);
    if (player == null || player.mahjongId == null || widget.currentEvent.gameLog.isEmpty) {
      return [];
    }

    List<FlSpot> spots = [];
    double currentScore = 0.0;
    int gamesPlayed = 0;

    // Filter game logs to only include games where this player participated
    List<GameLogEntry> playerGames = widget.currentEvent.gameLog.where((game) {
      return game.results.any((result) => result.id == player.mahjongId);
    }).toList();

    // Sort player's games by timestamp
    playerGames.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));

    for (var game in playerGames) {
      for (var result in game.results) {
        if (result.id == player.mahjongId) {
          currentScore += result.finalScore;
          gamesPlayed++;
          spots.add(FlSpot(gamesPlayed.toDouble(), currentScore));
          break; // Assuming a player only appears once per game log entry
        }
      }
    }
    return spots;
  }

  // Calculates score trend for a single team
  List<FlSpot> _getTeamScoreTrendLineData(String teamName) {
    if (widget.currentEvent.gameLog.isEmpty) {
      return [];
    }

    Map<DateTime, double> dailyTeamScores = {};
    double cumulativeTeamScore = 0.0;

    List<Player> teamPlayers = widget.currentEvent.playerBaseData.where((p) => p.team == teamName).toList();
    Set<String> teamPlayerMahjongIds = teamPlayers.map((p) => p.mahjongId!).whereType<String>().toSet();

    List<GameLogEntry> sortedGameLogs = List.from(widget.currentEvent.gameLog);
    sortedGameLogs.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));

    for (var game in sortedGameLogs) {
      final gameDate = DateTime.parse(game.timestamp);
      final dateOnly = DateTime(gameDate.year, gameDate.month, gameDate.day);

      double gameScoreForTeam = 0.0;
      for (var result in game.results) {
        if (teamPlayerMahjongIds.contains(result.id)) {
          gameScoreForTeam += result.finalScore;
        }
      }
      cumulativeTeamScore += gameScoreForTeam;
      dailyTeamScores[dateOnly] = cumulativeTeamScore;
    }

    List<FlSpot> spots = [];
    if (dailyTeamScores.isNotEmpty) {
      final firstDate = dailyTeamScores.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      final lastDate = dailyTeamScores.keys.reduce((a, b) => a.isAfter(b) ? a : b);

      DateTime currentDate = firstDate;
      double lastKnownScore = 0.0;

      while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
        if (dailyTeamScores.containsKey(currentDate)) {
          lastKnownScore = dailyTeamScores[currentDate]!;
        }
        spots.add(FlSpot(currentDate.millisecondsSinceEpoch.toDouble(), lastKnownScore));
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    return spots;
  }

  // Calculates score trend for all teams
  List<LineChartBarData> _getAllTeamsScoreTrendLineData() {
    if (widget.currentEvent.gameLog.isEmpty) {
      return [];
    }

    Map<String, Map<DateTime, double>> dailyTeamScoresOverTime = {};
    Map<String, double> currentTeamScores = {};

    List<String> allTeamNames = _getAllTeamNames();
    for (var teamName in allTeamNames) {
      currentTeamScores[teamName] = 0.0;
      dailyTeamScoresOverTime[teamName] = {};
    }

    Map<String, String> mahjongIdToTeamMap = {};
    for (var player in widget.currentEvent.playerBaseData) {
      if (player.mahjongId != null) {
        mahjongIdToTeamMap[player.mahjongId!] = player.team;
      }
    }

    List<GameLogEntry> sortedGameLogs = List.from(widget.currentEvent.gameLog);
    sortedGameLogs.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));

    for (var game in sortedGameLogs) {
      final gameDate = DateTime.parse(game.timestamp);
      final dateOnly = DateTime(gameDate.year, gameDate.month, gameDate.day);

      Map<String, double> gameScoresByTeam = {};
      for (var result in game.results) {
        String? teamName = mahjongIdToTeamMap[result.id];
        if (teamName != null) {
          gameScoresByTeam[teamName] = (gameScoresByTeam[teamName] ?? 0.0) + result.finalScore;
        }
      }

      for (var teamName in allTeamNames) {
        currentTeamScores[teamName] = (currentTeamScores[teamName] ?? 0.0) + (gameScoresByTeam[teamName] ?? 0.0);
        dailyTeamScoresOverTime[teamName]![dateOnly] = currentTeamScores[teamName]!;
      }
    }

    List<LineChartBarData> lineBarsData = [];
    if (dailyTeamScoresOverTime.isNotEmpty) {
      // Determine the overall date range across all teams
      DateTime? overallFirstDate;
      DateTime? overallLastDate;

      for (var teamName in allTeamNames) {
        final teamDailyScores = dailyTeamScoresOverTime[teamName];
        if (teamDailyScores != null && teamDailyScores.isNotEmpty) {
          final firstDate = teamDailyScores.keys.reduce((a, b) => a.isBefore(b) ? a : b);
          final lastDate = teamDailyScores.keys.reduce((a, b) => a.isAfter(b) ? a : b);

          if (overallFirstDate == null || firstDate.isBefore(overallFirstDate)) {
            overallFirstDate = firstDate;
          }
          if (overallLastDate == null || lastDate.isAfter(overallLastDate)) {
            overallLastDate = lastDate;
          }
        }
      }

      if (overallFirstDate != null && overallLastDate != null) {
        for (var teamName in allTeamNames) {
          List<FlSpot> spots = [];
          final teamDailyScores = dailyTeamScoresOverTime[teamName] ?? {};
          double lastKnownScore = 0.0; // Start with 0 for each team

          DateTime currentDate = overallFirstDate;
          while (currentDate.isBefore(overallLastDate) || currentDate.isAtSameMomentAs(overallLastDate)) {
            if (teamDailyScores.containsKey(currentDate)) {
              lastKnownScore = teamDailyScores[currentDate]!;
            }
            spots.add(FlSpot(currentDate.millisecondsSinceEpoch.toDouble(), lastKnownScore));
            currentDate = currentDate.add(const Duration(days: 1));
          }

          lineBarsData.add(
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: widget.teamColorMap[teamName] ?? Colors.grey,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }
      }
    }
    return lineBarsData;
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> dropdownItems = [];

    // Add players to dropdown
    for (var player in widget.playerDf) {
      dropdownItems.add(
        DropdownMenuItem(
          value: 'player_${player.name}',
          child: Text('选手: ${player.name}'),
        ),
      );
    }

    // Add teams to dropdown if it's a team event
    if (widget.currentEvent.isTeamEvent) {
      for (var teamName in _getAllTeamNames()) {
        dropdownItems.add(
          DropdownMenuItem(
            value: 'team_$teamName',
            child: Text('队伍: $teamName'),
          ),
        );
      }
      dropdownItems.add(
        DropdownMenuItem(
          value: 'all_teams',
          child: const Text('所有队伍总分'),
        ),
      );
    }

    // Determine the currently selected value for the dropdown
    String? currentDropdownValue;
    if (_selectedChartType == 'player' && _selectedEntityName != null) {
      currentDropdownValue = 'player_$_selectedEntityName';
    } else if (_selectedChartType == 'team' && _selectedEntityName != null) {
      currentDropdownValue = 'team_$_selectedEntityName';
    } else if (_selectedChartType == 'all_teams') {
      currentDropdownValue = 'all_teams';
    }

    // Ensure a valid initial selection if currentDropdownValue is null
    if (currentDropdownValue == null && dropdownItems.isNotEmpty) {
      currentDropdownValue = dropdownItems.first.value;
      // Also update state variables to reflect this initial selection
      if (currentDropdownValue!.startsWith('player_')) {
        _selectedChartType = 'player';
        _selectedEntityName = currentDropdownValue.substring('player_'.length);
      } else if (currentDropdownValue.startsWith('team_')) {
        _selectedChartType = 'team';
        _selectedEntityName = currentDropdownValue.substring('team_'.length);
      } else if (currentDropdownValue == 'all_teams') {
        _selectedChartType = 'all_teams';
        _selectedEntityName = '所有队伍总分';
      }
    }


    List<LineChartBarData> lineBarsData = [];
    String chartTitle = "请选择分析对象";
    String bottomTitleText = "";

    if (_selectedChartType == 'player' && _selectedEntityName != null) {
      Player? selectedPlayer = widget.playerDf.firstWhereOrNull((p) => p.name == _selectedEntityName!);
      lineBarsData = [
        LineChartBarData(
          spots: _getPlayerScoreTrendLineData(_selectedEntityName!),
          isCurved: false, // 修改为非平滑曲线
          color: widget.teamColorMap[selectedPlayer?.team] ?? Colors.grey, // 使用安全访问
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true), // 显示点
          belowBarData: BarAreaData(show: false),
        ),
      ];
      chartTitle = '选手 ${_selectedEntityName!} 总分趋势图';
      bottomTitleText = '半庄数'; // 玩家横坐标改回半庄数
    } else if (_selectedChartType == 'team' && _selectedEntityName != null) {
      lineBarsData = [
        LineChartBarData(
          spots: _getTeamScoreTrendLineData(_selectedEntityName!),
          isCurved: false, // 修改为非平滑曲线
          color: widget.teamColorMap[_selectedEntityName!] ?? Colors.grey,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true), // 显示点
          belowBarData: BarAreaData(show: false),
        ),
      ];
      chartTitle = '队伍 ${_selectedEntityName!} 总分趋势图';
      bottomTitleText = '日期';
    } else if (_selectedChartType == 'all_teams') {
      lineBarsData = _getAllTeamsScoreTrendLineData();
      chartTitle = '所有队伍总分趋势图';
      bottomTitleText = '日期';
    }

    // Calculate min/max X for interval calculation
    double minX = 0;
    double maxX = 1;
    if (lineBarsData.isNotEmpty) {
      minX = lineBarsData.map((barData) => barData.spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b)).reduce((a, b) => a < b ? a : b);
      maxX = lineBarsData.map((barData) => barData.spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b)).reduce((a, b) => a > b ? a : b);
    }

    double intervalX = 1.0; // Default for half-game count
    if (bottomTitleText == '日期' && lineBarsData.isNotEmpty) {
      // Calculate interval based on date range
      final minDateTime = DateTime.fromMillisecondsSinceEpoch(minX.toInt());
      final maxDateTime = DateTime.fromMillisecondsSinceEpoch(maxX.toInt());
      final duration = maxDateTime.difference(minDateTime);

      if (duration.inDays > 365 * 2) { // More than 2 years
        intervalX = const Duration(days: 365).inMilliseconds.toDouble();
      } else if (duration.inDays > 365 / 2) { // More than 6 months
        intervalX = const Duration(days: 180).inMilliseconds.toDouble();
      } else if (duration.inDays > 30) { // More than a month
        intervalX = const Duration(days: 7).inMilliseconds.toDouble();
      } else if (duration.inDays > 7) { // More than a week
        intervalX = const Duration(days: 1).inMilliseconds.toDouble();
      } else { // Less than a week, show hourly or daily
        intervalX = const Duration(hours: 24).inMilliseconds.toDouble();
      }
    }


    return AlertDialog(
      title: const Text("数据分析"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            DropdownButton<String>(
              value: currentDropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    if (newValue.startsWith('player_')) {
                      _selectedChartType = 'player';
                      _selectedEntityName = newValue.substring('player_'.length);
                    } else if (newValue.startsWith('team_')) {
                      _selectedChartType = 'team';
                      _selectedEntityName = newValue.substring('team_'.length);
                    } else if (newValue == 'all_teams') {
                      _selectedChartType = 'all_teams';
                      _selectedEntityName = '所有队伍总分'; // Placeholder name
                    }
                  }
                });
              },
              items: dropdownItems,
            ),
            const SizedBox(height: 20),
            Text(chartTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: lineBarsData.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true), // 显示网格线
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: bottomTitleText == '半庄数' ? 1.0 : intervalX, // 半庄数固定间隔1
                              getTitlesWidget: (value, meta) {
                                if (bottomTitleText == '半庄数') {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10)), // 只显示数字
                                  );
                                } else if (bottomTitleText == '日期') {
                                  final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text(DateFormat('MM-dd').format(dateTime), style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xff37434d), width: 1),
                        ),
                        lineBarsData: lineBarsData,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                String xLabel;
                                if (bottomTitleText == '半庄数') {
                                  xLabel = '半庄数: ${touchedSpot.x.toInt()}'; // 加上注释
                                } else if (bottomTitleText == '日期') {
                                  final dateTime = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                                  xLabel = '日期: ${DateFormat('yyyy-MM-dd HH:mm').format(dateTime)}';
                                } else {
                                  xLabel = 'X: ${touchedSpot.x.toStringAsFixed(0)}';
                                }
                                return LineTooltipItem(
                                  '$xLabel\n得分: ${touchedSpot.y.toStringAsFixed(2)}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("关闭"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
