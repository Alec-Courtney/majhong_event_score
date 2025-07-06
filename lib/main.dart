import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:html' as html; // For web-specific functionalities like downloading files
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import

import 'models/player.dart';
import 'models/game_log.dart';
import 'dart:ui' as ui; // Import for toImage
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/rendering.dart'; // Import for RenderRepaintBoundary
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize notifications for web

  runApp(
    MaterialApp(
      title: '雀魂联赛计分器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Player> playerBaseData = [];
  List<GameLogEntry> gameLog = [];
  List<Player> playerDf = []; // This will hold calculated player stats
  List<Team> teamDf = []; // This will hold calculated team stats
  Map<String, String> playerToTeam = {};
  List<String> allTeams = [];
  Map<String, Color> teamColorMap = {};

  final Uuid uuid = const Uuid();

  final GlobalKey _playerTableKey = GlobalKey();
  final GlobalKey _teamTableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAndPrepareData();
  }

  Future<void> _loadAndPrepareData() async {
    try {
      if (kIsWeb) {
        await _loadDataFromUrl();
      } else {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Load player_data
        final String? savedPlayerJsonString = prefs.getString('player_data');
        if (savedPlayerJsonString != null && savedPlayerJsonString.isNotEmpty) {
          final List<dynamic> playerJson = json.decode(savedPlayerJsonString);
          playerBaseData = playerJson.map((e) => Player.fromJson(e)).toList();
          _showInfoDialog("已从本地存储加载选手数据。");
        } else {
          final String playerJsonString =
              await rootBundle.loadString('assets/player_data.json');
          final List<dynamic> playerJson = json.decode(playerJsonString);
          playerBaseData = playerJson.map((e) => Player.fromJson(e)).toList();
          _showInfoDialog("已从资产文件加载初始选手数据。");
        }

        // Load game_log
        final String? savedGameLogString = prefs.getString('game_log');
        if (savedGameLogString != null && savedGameLogString.isNotEmpty) {
          final List<dynamic> gameLogJson = json.decode(savedGameLogString);
          gameLog = gameLogJson.map((e) => GameLogEntry.fromJson(e)).toList();
          _showInfoDialog("已从本地存储加载比赛记录。");
        } else {
          final String gameLogJsonString =
              await rootBundle.loadString('assets/game_log.json');
          final List<dynamic> gameLogJson = json.decode(gameLogJsonString);
          gameLog = gameLogJson.map((e) => GameLogEntry.fromJson(e)).toList();
          _showInfoDialog("已从资产文件加载初始比赛记录。");
        }
      }

      _populateTeamData();
      _recalculateAllStatsFromLog();
    } catch (e) {
      _showErrorDialog("无法加载数据文件: $e");
    }
  }

  Future<void> _loadDataFromUrl() async {
    const String baseUrl = 'https://raw.githubusercontent.com/Alec-Courteny/majhong_event_score/main/assets/';
    try {
      // Load player_data
      final playerResponse = await http.get(Uri.parse('${baseUrl}player_data.json'));
      if (playerResponse.statusCode == 200) {
        final List<dynamic> playerJson = json.decode(utf8.decode(playerResponse.bodyBytes));
        playerBaseData = playerJson.map((e) => Player.fromJson(e)).toList();
        _showInfoDialog("已从网络加载选手数据。");
      } else {
        throw Exception('Failed to load player data');
      }

      // Load game_log
      final gameLogResponse = await http.get(Uri.parse('${baseUrl}game_log.json'));
      if (gameLogResponse.statusCode == 200) {
        final List<dynamic> gameLogJson = json.decode(utf8.decode(gameLogResponse.bodyBytes));
        gameLog = gameLogJson.map((e) => GameLogEntry.fromJson(e)).toList();
        _showInfoDialog("已从网络加载比赛记录。");
      } else {
        throw Exception('Failed to load game log');
      }
    } catch (e) {
      _showErrorDialog("从网络加载数据失败: $e");
      // Fallback to assets if network fails
      final String playerJsonString =
          await rootBundle.loadString('assets/player_data.json');
      final List<dynamic> playerJson = json.decode(playerJsonString);
      playerBaseData = playerJson.map((e) => Player.fromJson(e)).toList();

      final String gameLogJsonString =
          await rootBundle.loadString('assets/game_log.json');
      final List<dynamic> gameLogJson = json.decode(gameLogJsonString);
      gameLog = gameLogJson.map((e) => GameLogEntry.fromJson(e)).toList();
      _showInfoDialog("已从备用资产文件加载数据。");
    }
  }

  void _populateTeamData() {
    playerToTeam = {for (var p in playerBaseData) p.mahjongId: p.team};
    allTeams = playerBaseData.map((p) => p.team).toSet().toList()..sort();
    teamColorMap = _getTeamColorMap();
  }

  Map<String, Color> _getTeamColorMap() {
    // This is a simplified version. In a real app, you might load this from a config.
    // For now, let's assign some default colors.
    final List<Color> colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.brown, Colors.cyan,
    ];
    final Map<String, Color> map = {};
    for (int i = 0; i < allTeams.length; i++) {
      map[allTeams[i]] = colors[i % colors.length];
    }
    return map;
  }

  void _recalculateAllStatsFromLog() {
    // Reset player stats
    playerDf = playerBaseData.map((p) {
      final newPlayer = Player(name: p.name, mahjongId: p.mahjongId, team: p.team);
      newPlayer.resetStats(); // Reset all mutable stats
      return newPlayer;
    }).toList();

    // Create a map for quick lookup by mahjongId
    final Map<String, Player> playerMap = {for (var p in playerDf) p.mahjongId: p};
    final Map<String, List<int>> playerRawScores = {for (var p in playerDf) p.mahjongId: []};

    // Reset team stats
    teamDf = allTeams.map((teamName) => Team(name: teamName)).toList();
    final Map<String, Team> teamMap = {for (var t in teamDf) t.name: t};

    for (var game in gameLog) {
      for (var result in game.results) {
        final player = playerMap[result.id];
        if (player == null) continue;

        final teamName = playerToTeam[player.mahjongId];
        if (teamName == null) continue;
        final team = teamMap[teamName];
        if (team == null) continue;

        player.score += result.finalScore;
        player.gamesPlayed += 1;
        switch (result.rank) {
          case 1: player.rank1 += 1; break;
          case 2: player.rank2 += 1; break;
          case 3: player.rank3 += 1; break;
          case 4: player.rank4 += 1; break;
        }
        if (result.score > player.highestScore) {
          player.highestScore = result.score;
        }
        playerRawScores[player.mahjongId]?.add(result.score);

        team.score += result.finalScore;
        team.gamesPlayed += 1;
        switch (result.rank) {
          case 1: team.rank1 += 1; break;
          case 2: team.rank2 += 1; break;
          case 3: team.rank3 += 1; break;
          case 4: team.rank4 += 1; break;
        }
      }
    }

    // Calculate derived player stats
    for (var player in playerDf) {
      if (player.gamesPlayed > 0) {
        player.avoidFourthRate = ((player.rank1 + player.rank2 + player.rank3) / player.gamesPlayed) * 100;
        player.consecutiveWinRate = ((player.rank1 + player.rank2) / player.gamesPlayed) * 100;
        player.averageRank = (player.rank1 * 1 + player.rank2 * 2 + player.rank3 * 3 + player.rank4 * 4) / player.gamesPlayed;
        player.averageGameScore = playerRawScores[player.mahjongId]!.reduce((a, b) => a + b) / player.gamesPlayed;
      }
    }

    // Sort players and teams
    playerDf.sort((a, b) => b.score.compareTo(a.score));
    teamDf.sort((a, b) => b.score.compareTo(a.score));

    // Calculate team score difference
    if (teamDf.isNotEmpty) {
      for (int i = 0; i < teamDf.length; i++) {
        if (i == 0) {
          teamDf[i].scoreDifference = 0.0; // Top team has no difference
        } else {
          teamDf[i].scoreDifference = (teamDf[i].score - teamDf[i-1].score).abs();
        }
      }
    }

    setState(() {}); // Update UI
  }

  Future<void> _showErrorDialog(String message) async {
    // For web, use local notifications or a simple alert dialog
    // For web, use a simple JS alert
    html.window.alert("错误: $message");
  }

  Future<void> _showInfoDialog(String message) async {
    // For web, use a simple JS alert
    html.window.alert("信息: $message");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('雀魂联赛计分器'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputSection(),
              const SizedBox(height: 20),
              _buildControlButtons(),
              const SizedBox(height: 20),
              SingleChildScrollView( // Wrap DataTable in SingleChildScrollView for horizontal scrolling
                scrollDirection: Axis.horizontal,
                child: _buildPlayerRankingTable(),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView( // Wrap DataTable in SingleChildScrollView for horizontal scrolling
                scrollDirection: Axis.horizontal,
                child: _buildTeamRankingTable(),
              ),
            ],
          ),
        ),
      );
  }

  final List<TextEditingController> _idControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _scoreControllers =
      List.generate(4, (_) => TextEditingController());

  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('比赛结果输入',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('选手 ${i + 1} ID:'),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _idControllers[i].text.isEmpty
                            ? null
                            : _idControllers[i].text,
                        hint: const Text('选择或输入雀魂ID'),
                        items: playerBaseData.map((player) {
                          return DropdownMenuItem(
                            value: player.mahjongId,
                            child: Text('${player.name} (${player.mahjongId})'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _idControllers[i].text = newValue ?? '';
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 80,
                      child: Text('场内分数:'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _scoreControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _calculateAndUpdate,
          child: const Text('计算并更新'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _openEditPlayerWindow,
          child: const Text('修改选手信息'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _openAnalysisWindow,
          child: const Text('查看数据分析'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _openLogManagementWindow,
          child: const Text('管理比赛记录'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _exportGraphicalReport,
          child: const Text('导出图文报告'),
        ),
      ],
    );
  }

  Widget _buildPlayerRankingTable() {
    final List<String> playerColsToDisplay = [
      '队员', '雀魂ID', '分数', '半庄数', '1位', '2位', '3位', '4位', '最高得点',
      '避四率', '连对率', '平均顺位', '平均场分'
    ];

    return RepaintBoundary( // Use RepaintBoundary instead of Screenshot
      key: _playerTableKey, // Assign GlobalKey
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选手数据榜',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1200),
                child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    columns: playerColsToDisplay
                        .map((col) => DataColumn(label: Text(col)))
                        .toList(),
                    rows: playerDf.map((player) {
                      return DataRow(
                        cells: playerColsToDisplay.map((col) {
                          String text;
                          switch (col) {
                            case '队员':
                              text = player.name;
                              break;
                            case '雀魂ID':
                              text = player.mahjongId;
                              break;
                            case '分数':
                              text = player.score.toStringAsFixed(1);
                              break;
                            case '半庄数':
                              text = player.gamesPlayed.toString();
                              break;
                            case '1位':
                              text = player.rank1.toString();
                              break;
                            case '2位':
                              text = player.rank2.toString();
                              break;
                            case '3位':
                              text = player.rank3.toString();
                              break;
                            case '4位':
                              text = player.rank4.toString();
                              break;
                            case '最高得点':
                              text = player.highestScore.toString();
                              break;
                            case '避四率':
                              text = '${player.avoidFourthRate.toStringAsFixed(1)}%';
                              break;
                            case '连对率':
                              text = '${player.consecutiveWinRate.toStringAsFixed(1)}%';
                              break;
                            case '平均顺位':
                              text = player.averageRank.toStringAsFixed(1);
                              break;
                            case '平均场分':
                              text = player.averageGameScore.toStringAsFixed(0);
                              break;
                            default:
                              text = '';
                          }
                          return DataCell(Text(text));
                        }).toList(),
                      );
                    }).toList(),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRankingTable() {
    final List<String> teamColsToDisplay = [
      '队伍', '分数', '分差', '半庄数', '1位', '2位', '3位', '4位'
    ];

    return RepaintBoundary( // Use RepaintBoundary instead of Screenshot
      key: _teamTableKey, // Assign GlobalKey
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('队伍积分榜',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    columns: teamColsToDisplay
                        .map((col) => DataColumn(label: Text(col)))
                        .toList(),
                    rows: teamDf.map((team) {
                      return DataRow(
                        cells: teamColsToDisplay.map((col) {
                          String text;
                          switch (col) {
                            case '队伍':
                              text = team.name;
                              break;
                            case '分数':
                              text = team.score.toStringAsFixed(1);
                              break;
                            case '分差':
                              text = team.scoreDifference == 0.0
                                  ? '-'
                                  : team.scoreDifference.toStringAsFixed(1);
                              break;
                            case '半庄数':
                              text = team.gamesPlayed.toString();
                              break;
                            case '1位':
                              text = team.rank1.toString();
                              break;
                            case '2位':
                              text = team.rank2.toString();
                              break;
                            case '3位':
                              text = team.rank3.toString();
                              break;
                            case '4位':
                              text = team.rank4.toString();
                              break;
                            default:
                              text = '';
                          }
                          return DataCell(Text(text));
                        }).toList(),
                      );
                    }).toList(),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateAndUpdate() {
    List<Map<String, dynamic>> gameData = [];
    List<String> playerIdsInGame = [];
    int totalRawScore = 0;

    for (int i = 0; i < 4; i++) {
      String playerId = _idControllers[i].text.trim();
      String scoreStr = _scoreControllers[i].text.trim();

      if (playerId.isEmpty || scoreStr.isEmpty) {
        continue;
      }

      if (!playerToTeam.containsKey(playerId)) {
        _showErrorDialog("未找到选手ID: $playerId");
        return;
      }

      int? score = int.tryParse(scoreStr);
      if (score == null) {
        _showErrorDialog("选手 $playerId 的分数必须是数字。");
        return;
      }

      gameData.add({'id': playerId, 'score': score});
      playerIdsInGame.add(playerId);
      totalRawScore += score;
    }

    if (gameData.length != 4) {
      _showErrorDialog("必须输入四名选手的数据。");
      return;
    }
    if (playerIdsInGame.toSet().length != 4) {
      _showErrorDialog("错误：一局内的四名选手不能重复。");
      return;
    }
    if (playerIdsInGame.map((id) => playerToTeam[id]).toSet().length != 4) {
      _showErrorDialog("错误：一局内的四名选手必须来自不同的队伍。");
      return;
    }
    if (totalRawScore != 100000) {
      _showErrorDialog("错误：四名选手的场内总分必须为 100000，当前为 $totalRawScore。");
      return;
    }

    gameData.sort((a, b) => b['score'].compareTo(a['score']));
    Map<int, int> basePoints = {1: 50, 2: 10, 3: -10, 4: -30};

    List<GameResult> results = [];
    for (int i = 0; i < gameData.length; i++) {
      int rank = i + 1;
      double finalScore = (gameData[i]['score'] - 30000) / 1000 + basePoints[rank]!;
      results.add(GameResult(
        id: gameData[i]['id'],
        score: gameData[i]['score'],
        rank: rank,
        finalScore: finalScore,
      ));
    }
    _showAdjustmentWindow(results);
  }

  Future<void> _showAdjustmentWindow(List<GameResult> gameResults, {String? existingGameId}) async {
    final TextEditingController dateController = TextEditingController();
    if (existingGameId != null) {
      final game = gameLog.firstWhere((g) => g.gameId == existingGameId);
      try {
        dateController.text = DateTime.parse(game.timestamp).toLocal().toString().split(' ')[0];
      } catch (e) {
        dateController.text = game.timestamp.split(' ')[0];
      }
    } else {
      dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
    }

    List<GameResult> adjustedResults = List.from(gameResults);
    List<TextEditingController> rankControllers = adjustedResults.map((e) => TextEditingController(text: e.rank.toString())).toList();
    List<TextEditingController> scoreControllers = adjustedResults.map((e) => TextEditingController(text: e.finalScore.toStringAsFixed(2))).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existingGameId != null ? "修改比赛记录" : "确认比赛结果"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("比赛日期 (YYYY-MM-DD):"),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          hintText: 'YYYY-MM-DD',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("请确认或修改最终得分和位次："),
                const SizedBox(height: 10),
                for (int i = 0; i < adjustedResults.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text('选手: ${adjustedResults[i].id}'),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: rankControllers[i],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '位次'),
                            onChanged: (value) {
                              // Update rank in adjustedResults
                              adjustedResults[i].rank = int.tryParse(value) ?? adjustedResults[i].rank;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: scoreControllers[i],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '分数'),
                            onChanged: (value) {
                              // Update finalScore in adjustedResults
                              adjustedResults[i].finalScore = double.tryParse(value) ?? adjustedResults[i].finalScore;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("确认"),
              onPressed: () {
                final newDate = dateController.text.trim();
                try {
                  DateTime.parse(newDate); // Validate date format
                } catch (e) {
                  _showErrorDialog("日期格式不正确，必须是 YYYY-MM-DD。");
                  return;
                }

                if (existingGameId != null) {
                  _updateGameInLog(existingGameId, adjustedResults, newTimestamp: newDate);
                } else {
                  _addGameToLog(adjustedResults, timestamp: newDate);
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGameToLog(List<GameResult> gameResults, {String? timestamp}) async {
    final String gameId = uuid.v4();
    final String ts = timestamp ?? DateTime.now().toLocal().toString().split(' ')[0];
    final newLogEntry = GameLogEntry(gameId: gameId, timestamp: ts, results: gameResults);
    gameLog.add(newLogEntry);
    gameLog.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));
    await _saveGameLog();
    _showInfoDialog("比赛记录已添加。");
    _recalculateAllStatsFromLog();
    _clearInputFields();
  }

  Future<void> _updateGameInLog(String gameId, List<GameResult> updatedResults, {String? newTimestamp}) async {
    final gameIndex = gameLog.indexWhere((game) => game.gameId == gameId);
    if (gameIndex != -1) {
      gameLog[gameIndex] = GameLogEntry(
        gameId: gameId,
        timestamp: newTimestamp ?? gameLog[gameIndex].timestamp,
        results: updatedResults,
      );
      gameLog.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));
      await _saveGameLog();
      _showInfoDialog("比赛记录已更新。");
      _recalculateAllStatsFromLog();
    } else {
      _showErrorDialog("找不到要更新的比赛记录。");
    }
  }

  Future<void> _saveGameLog() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(gameLog.map((e) => e.toJson()).toList());
      await prefs.setString('game_log', jsonString);
      // For web, we also need to provide a download option for the user to persist data
      // This is a simplified approach. A more robust solution might involve a backend.
      // Or, for a true "save to file" experience on web, use a dedicated download button.
    } catch (e) {
      _showErrorDialog("无法写入比赛记录文件: $e");
    }
  }

  void _clearInputFields() {
    for (var controller in _idControllers) {
      controller.clear();
    }
    for (var controller in _scoreControllers) {
      controller.clear();
    }
  }


  void _openEditPlayerWindow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPlayerMahjongId;
        TextEditingController newNameController = TextEditingController();
        TextEditingController newIdController = TextEditingController();

        return AlertDialog(
          title: const Text("修改选手信息"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPlayerMahjongId,
                    hint: const Text("选择要修改的选手"),
                    items: playerBaseData.map((player) {
                      return DropdownMenuItem(
                        value: player.mahjongId,
                        child: Text('${player.name} (${player.mahjongId})'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPlayerMahjongId = newValue;
                        if (newValue != null) {
                          final playerInfo = playerBaseData.firstWhere(
                              (p) => p.mahjongId == newValue);
                          newNameController.text = playerInfo.name;
                          newIdController.text = playerInfo.mahjongId;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newNameController,
                    decoration: const InputDecoration(labelText: "新队员名"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newIdController,
                    decoration: const InputDecoration(labelText: "新雀魂ID"),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("保存更改"),
              onPressed: () async {
                if (selectedPlayerMahjongId == null ||
                    newNameController.text.trim().isEmpty ||
                    newIdController.text.trim().isEmpty) {
                  _showErrorDialog("所有字段都不能为空。");
                  return;
                }

                final originalPlayerIndex = playerBaseData.indexWhere(
                    (p) => p.mahjongId == selectedPlayerMahjongId);

                if (originalPlayerIndex != -1) {
                  // Update playerBaseData
                  playerBaseData[originalPlayerIndex] = Player(
                    name: newNameController.text.trim(),
                    mahjongId: newIdController.text.trim(),
                    team: playerBaseData[originalPlayerIndex].team, // Keep original team
                  );

                  // Update playerToTeam map
                  playerToTeam = {for (var p in playerBaseData) p.mahjongId: p.team};

                  // Save updated playerBaseData to SharedPreferences
                  try {
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    final String jsonString = json.encode(playerBaseData.map((e) => e.toJson()).toList());
                    await prefs.setString('player_data', jsonString);
                    _showInfoDialog("选手信息已更新。");
                    _recalculateAllStatsFromLog(); // Recalculate all stats with updated player info
                    Navigator.of(context).pop();
                  } catch (e) {
                    _showErrorDialog("无法写入JSON文件: $e");
                  }
                } else {
                  _showErrorDialog("找不到原始选手数据。");
                }
              },
            ),
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openLogManagementWindow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("管理比赛记录"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
            height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: gameLog.length,
                    itemBuilder: (context, index) {
                      final game = gameLog[index];
                      final players = game.results.map((r) => r.id).join(', ');
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('游戏ID: ${game.gameId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('日期: ${game.timestamp}'),
                                    Text('选手: $players'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close current dialog
                                  _showAdjustmentWindow(game.results, existingGameId: game.gameId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("确认删除"),
                                        content: Text("确定要永久删除比赛记录 ${game.gameId} 吗？\n此操作无法撤销。"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text("取消"),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("删除"),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirm == true) {
                                    setState(() {
                                      gameLog.removeWhere((g) => g.gameId == game.gameId);
                                    });
                                    await _saveGameLog();
                                    _showInfoDialog("比赛记录已删除。");
                                    _recalculateAllStatsFromLog();
                                    // Rebuild the dialog to reflect changes
                                    Navigator.of(context).pop(); // Close current dialog
                                    _openLogManagementWindow(); // Reopen to refresh
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
      },
    );
  }

  void _openAnalysisWindow() {
    // TODO: Implement analysis window
    _showInfoDialog("数据分析功能待实现。");
  }

  Future<void> _exportGraphicalReport() async {
    _showInfoDialog("正在生成图文报告...");

    try {
      // Capture player table
      RenderRepaintBoundary? playerBoundary = _playerTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image? playerImage = await playerBoundary?.toImage(pixelRatio: 2.0); // Capture at 2x resolution
      ByteData? playerByteData = await playerImage?.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? playerBytes = playerByteData?.buffer.asUint8List();

      // Capture team table
      RenderRepaintBoundary? teamBoundary = _teamTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image? teamImage = await teamBoundary?.toImage(pixelRatio: 2.0); // Capture at 2x resolution
      ByteData? teamByteData = await teamImage?.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? teamBytes = teamByteData?.buffer.asUint8List();

      if (playerBytes != null) {
        _downloadImage(playerBytes, 'player_ranking.png');
      } else {
        _showErrorDialog("无法捕获选手数据榜图片。");
      }

      if (teamBytes != null) {
        _downloadImage(teamBytes, 'team_ranking.png');
      } else {
        _showErrorDialog("无法捕获队伍积分榜图片。");
      }

      _showInfoDialog("图文报告已生成并提供下载。");
    } catch (e) {
      _showErrorDialog("生成图文报告时发生错误: $e");
    }
  }

  void _downloadImage(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

// Define Team model (since it's not in a separate file yet)
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

  // No fromJson/toJson needed for now as it's derived data
}
