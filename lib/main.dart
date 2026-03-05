/// main.dart
///
/// 本文件是立直麻将赛事计分系统的主要入口文件，负责应用的初始化、状态管理、UI构建以及核心业务逻辑的处理。
///
/// 主要功能：
/// - 应用启动和初始化：设置Flutter绑定，运行主应用。
/// - 赛事数据管理：加载、保存、切换和管理多个赛事（Event）的数据。
/// - 比赛结果输入：提供用户界面，用于输入每局麻将比赛的选手ID和得分。
/// - 积分计算与更新：根据输入的比赛结果，实时计算并更新选手（Player）和队伍（Team）的各项统计数据。
/// - 数据展示：显示选手积分榜和队伍积分榜。
/// - 模块化对话框集成：通过独立的widget对话框管理选手信息、比赛记录、数据分析和列配置。
/// - 图文报告导出：支持将当前积分榜导出为PNG图片。
/// - 数据持久化：利用shared_preferences库将所有赛事数据持久化到本地存储。
///
/// 实现细节：
/// - `main()` 函数：应用的入口点，初始化Flutter并启动`SplashScreen`，然后过渡到`MainApp`。
/// - `MainApp` State：管理应用的核心状态，包括`allEvents`（所有赛事）、`currentEvent`（当前选中的赛事）、
///   `playerDf`（计算后的选手统计数据）、`teamDf`（计算后的队伍统计数据）等。
/// - `_loadAllEvents()`：从`shared_preferences`加载所有赛事数据，如果不存在则创建默认赛事。
/// - `_saveAllEvents()`：将当前所有赛事数据保存到`shared_preferences`。
/// - `_recalculateAllStatsFromLog()`：核心计算逻辑，遍历`currentEvent`中的`gameLog`，
///   根据比赛结果更新`playerDf`和`teamDf`中的各项统计数据（如总分、顺位、平均分等）。
/// - `_buildInputSection()`：构建比赛结果输入界面，包括选手ID下拉选择和得分输入框。
/// - `_buildPlayerRankingTable()` 和 `_buildTeamRankingTable()`：根据`currentEvent`的列配置和计算后的数据，
///   动态生成选手和队伍的积分表格。
/// - `_calculateAndUpdate()`：处理用户提交的比赛结果，进行数据校验，计算初始得分，并调用`_showAdjustmentWindow`进行确认。
/// - `_showAdjustmentWindow()`：弹出对话框，允许用户确认或修改比赛的最终得分和位次，并处理比赛记录的添加或更新。
/// - `_exportGraphicalReport()`：利用`RenderRepaintBoundary`捕获表格的视觉内容，并导出为PNG图片。
/// - 各管理对话框（`EventManagementDialog`, `PlayerManagementDialog`, `GameLogManagementDialog`, `AnalysisWindow`, `ColumnConfigDialog`）
///   通过回调函数与`MainApp`进行数据交互和状态更新。
///
/// 数据成员设计（核心数据流）：
/// - `allEvents` (List<Event>): 存储所有已创建的赛事对象。这是应用数据的主容器。
/// - `currentEvent` (Event?): 当前用户正在查看和操作的赛事。所有UI和计算都围绕此对象进行。
/// - `playerBaseData` (List<Player>): `currentEvent`内部存储的选手基础信息（姓名、ID、队伍）。
/// - `gameLog` (List<GameLogEntry>): `currentEvent`内部存储的比赛历史记录。
/// - `playerDf` (List<Player>): 从`playerBaseData`和`gameLog`计算得出的选手实时统计数据。
///   此列表中的Player对象包含动态更新的统计字段。
/// - `teamDf` (List<Team>): 从`playerDf`和`gameLog`计算得出的队伍实时统计数据。
/// - `playerToTeam` (Map<String, String>): 雀魂ID到队伍名称的映射，用于快速查找。
/// - `allTeams` (List<String>): 当前赛事中所有队伍的名称列表。
/// - `teamColorMap` (Map<String, Color>): 队伍名称到颜色映射，用于图表显示。
///
/// 数据持久性设计：
/// - 应用启动时，`_loadAllEvents()` 方法通过`shared_preferences`从本地存储中读取名为`'all_events'`的JSON字符串。
/// - 如果读取到数据，则将其反序列化为`List<Event>`对象。
/// - 如果没有数据，则创建一个默认的四人麻将赛事并添加到`allEvents`中。
/// - 每次`allEvents`列表发生变化（例如添加新赛事、更新现有赛事中的选手或比赛记录）时，
///   `_saveAllEvents()` 方法会将整个`allEvents`列表序列化为JSON字符串，并保存回`shared_preferences`。
/// - `Event`、`Player`、`GameLogEntry`、`GameResult`、`ColumnConfig`等模型类都使用了`json_annotation`库，
///   自动生成`fromJson`和`toJson`方法，简化了JSON序列化和反序列化的过程，确保了数据结构的完整性和一致性。
/// - 这种设计确保了应用关闭后数据不会丢失，并在下次启动时能够恢复到上次的状态。
///
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
import 'models/team.dart'; // Import the new Team model
import 'models/event.dart'; // Import the new Event model
import 'models/column_config.dart'; // Import the ColumnConfig model
import 'dart:ui' as ui; // Import for toImage
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/rendering.dart'; // Import for RenderRepaintBoundary
import 'package:http/http.dart' as http;

import 'widgets/event_management_dialog.dart'; // Import the new EventManagementDialog
import 'widgets/player_management_dialog.dart'; // Import the new PlayerManagementDialog
import 'widgets/game_log_management_dialog.dart'; // Import the new GameLogManagementDialog
import 'widgets/analysis_window.dart'; // Import the new AnalysisWindow
import 'widgets/column_config_dialog.dart'; // Import the new ColumnConfigDialog
import 'widgets/splash_screen.dart'; // Import the new SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /// 初始化网页通知

  runApp(
    MaterialApp(
      title: '立直麻将赛事计分系统', /// 更新标题
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(nextScreen: MainApp()), /// 设置启动画面为初始屏幕
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Event> allEvents = [];
  Event? currentEvent;
  /// 添加加载状态
  bool _isLoading = false; 

  /// 这些现在将从currentEvent派生
  /// List<Player> playerBaseData = [];
  /// List<GameLogEntry> gameLog = [];
  /// 这将保存计算出的玩家统计数据
  List<Player> playerDf = []; 
  /// 这将保存计算出的团队统计数据
  List<Team> teamDf = []; 
  Map<String, String> playerToTeam = {};
  List<String> allTeams = [];
  Map<String, Color> teamColorMap = {};

  final Uuid uuid = const Uuid();

  final GlobalKey _playerTableKey = GlobalKey();
  final GlobalKey _teamTableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    setState(() {
      /// 显示加载指示器
      _isLoading = true; 
    });
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedEventsJsonString = prefs.getString('all_events');
      if (savedEventsJsonString != null && savedEventsJsonString.isNotEmpty) {
        final List<dynamic> eventJson = json.decode(savedEventsJsonString);
        allEvents = eventJson.map((e) => Event.fromJson(e)).toList();
        _showInfoDialog("已从本地存储加载所有赛事。");
        if (allEvents.isNotEmpty) {
          setState(() {
            /// 将第一个赛事设置为当前赛事
            currentEvent = allEvents.first; 
          });
          _prepareCurrentEventData();
        }
      } else {
        /// 如果没有赛事，则创建一个默认赛事
        final defaultEvent = Event.defaultFourPlayerEvent(eventId: uuid.v4(), eventName: "默认四人麻将赛事");
        allEvents.add(defaultEvent);
        setState(() {
          currentEvent = defaultEvent;
        });
        await _saveAllEvents();
        _showInfoDialog("已创建默认四人麻将赛事。");
      }
      _recalculateAllStatsFromLog(); /// 初始计算
    } catch (e) {
      _showErrorDialog("无法加载赛事数据: $e");
    } finally {
      setState(() {
        /// 隐藏加载指示器
        _isLoading = false; 
      });
    }
  }

  Future<void> _saveAllEvents() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(allEvents.map((e) => e.toJson()).toList());
      await prefs.setString('all_events', jsonString);
    } catch (e) {
      _showErrorDialog("无法保存赛事数据: $e");
    }
  }

  void _loadNewEventsData(List<Event> newEvents) {
    /// 数据迁移：修复旧数据中不正确的displayFormat。
    for (var event in newEvents) {
      try {
        var avgScoreColumn = event.playerColumns.firstWhere((c) => c.dataKey == 'averageGameScore');
        if (avgScoreColumn.displayFormat == 'integer') {
          avgScoreColumn.displayFormat = 'fixed1';
        }
      } catch (e) {
        /// 列可能不存在，忽略。
      }
    }

    setState(() {
      allEvents = newEvents;
      if (allEvents.isNotEmpty) {
        currentEvent = allEvents.first;
      } else {
        currentEvent = null;
      }
    });
    _prepareCurrentEventData();
    _recalculateAllStatsFromLog();
    _saveAllEvents();
  }

  void _prepareCurrentEventData() {
    if (currentEvent == null) return;

    /// 从currentEvent.playerBaseData填充playerToTeam和allTeams
    /// 过滤掉mahjongId为null的玩家，或者为他们生成一个临时的唯一ID作为键
    playerToTeam = {
      for (var p in currentEvent!.playerBaseData)
        if (p.mahjongId != null) p.mahjongId!: p.team
    };
    allTeams = currentEvent!.playerBaseData.map((p) => p.team).toSet().toList()..sort();
    teamColorMap = _getTeamColorMap();
  }

  Map<String, Color> _getTeamColorMap() {
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
    if (currentEvent == null) return;

    /// 重置玩家统计数据
    playerDf = currentEvent!.playerBaseData.map((p) {
      final newPlayer = Player(name: p.name, mahjongId: p.mahjongId, team: p.team);
      newPlayer.resetStats(); /// 重置所有可变统计数据
      return newPlayer;
    }).toList();

    /// 创建一个用于通过mahjongId快速查找的映射，过滤掉mahjongId为null的玩家
    final Map<String, Player> playerMap = {
      for (var p in playerDf)
        if (p.mahjongId != null) p.mahjongId!: p
    };
    final Map<String, List<int>> playerRawScores = {
      for (var p in playerDf)
        if (p.mahjongId != null) p.mahjongId!: []
    };

    /// 重置团队统计数据
    teamDf = allTeams.map((teamName) => Team(name: teamName)).toList();
    final Map<String, Team> teamMap = {for (var t in teamDf) t.name: t};

    for (var game in currentEvent!.gameLog) {
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

    /// 根据ColumnConfig计算派生玩家统计数据
    for (var player in playerDf) {
      if (player.gamesPlayed > 0) {
        for (var col in currentEvent!.playerColumns) {
          if (col.isPlayerColumn) {
            switch (col.calculationType) {
              case 'avoidFourthRate':
                player.avoidFourthRate = ((player.rank1 + player.rank2 + player.rank3) / player.gamesPlayed) * 100;
                break;
              case 'consecutiveWinRate':
                player.consecutiveWinRate = ((player.rank1 + player.rank2) / player.gamesPlayed) * 100;
                break;
              case 'averageRank':
                player.averageRank = (player.rank1 * 1 + player.rank2 * 2 + player.rank3 * 3 + player.rank4 * 4) / player.gamesPlayed;
                break;
              case 'averageGameScore':
                player.averageGameScore = playerRawScores[player.mahjongId]!.reduce((a, b) => a + b) / player.gamesPlayed;
                break;
              /// 在此处添加更多计算类型
            }
          }
        }
      }
    }

    /// 排序玩家和团队
    playerDf.sort((a, b) => b.score.compareTo(a.score));
    teamDf.sort((a, b) => b.score.compareTo(a.score));

    /// 计算团队分数差异
    if (teamDf.isNotEmpty) {
      for (int i = 0; i < teamDf.length; i++) {
        if (i == 0) {
          teamDf[i].scoreDifference = 0.0; /// 排名第一的团队没有差异
        } else {
          teamDf[i].scoreDifference = (teamDf[i].score - teamDf[i-1].score).abs();
        }
      }
    }

    setState(() {}); /// 更新UI
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    _showSnackBar(message, isError: true);
  }

  void _showInfoDialog(String message) {
    _showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('立直麻将赛事计分系统'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('正在加载赛事数据...'),
            ],
          ),
        ),
      );
    }

    if (currentEvent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('立直麻将赛事计分系统'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('无可用赛事。请创建新赛事。'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _openEventManagementWindow(context),
                child: const Text('管理赛事'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('立直麻将赛事计分系统 - ${currentEvent!.eventName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _openEventManagementWindow(context),
              tooltip: '管理赛事',
            ),
          ],
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
              SingleChildScrollView( /// 将DataTable包装在SingleChildScrollView中以实现水平滚动
                scrollDirection: Axis.horizontal,
                child: _buildPlayerRankingTable(),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView( /// 将DataTable包装在SingleChildScrollView中以实现水平滚动
                scrollDirection: Axis.horizontal,
                child: _buildTeamRankingTable(),
              ),
            ],
          ),
        ),
      );
  }

  /// 游戏输入控制器，初始化为最大玩家数（4）
  final List<TextEditingController> _idControllers = List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _scoreControllers = List.generate(4, (_) => TextEditingController());

  Widget _buildInputSection() {
    if (currentEvent == null) return const SizedBox.shrink();

    final int playerCount = currentEvent!.mahjongType == "三人麻将" ? 3 : 4;
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
            for (int i = 0; i < playerCount; i++)
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
                        hint: const Text('选择选手名称或者ID'),
                        items: currentEvent!.playerBaseData.map((player) {
                          /// 如果mahjongId为null，则使用一个默认值，例如空字符串或UUID
                          final String displayId = player.mahjongId ?? '无ID选手';
                          return DropdownMenuItem(
                            value: player.mahjongId, /// value仍然可以是null
                            child: Text('${player.name} (${displayId})'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _idControllers[i].text = newValue ?? ''; /// newValue可能是null
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
                      child: Text('终局点数:'),
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
    if (currentEvent == null) return const SizedBox.shrink();

    final List<DataColumn> columns = currentEvent!.playerColumns
        .where((col) => col.isPlayerColumn)
        .map((col) => DataColumn(label: Text(col.columnName)))
        .toList();

    final List<DataRow> rows = playerDf.map((player) {
      return DataRow(
        cells: currentEvent!.playerColumns
            .where((col) => col.isPlayerColumn)
            .map((col) {
          dynamic value;
          switch (col.dataKey) {
            case 'name':
              value = player.name;
              break;
            case 'mahjongId':
              value = player.mahjongId ?? '无ID'; /// 如果mahjongId为null，显示“无ID”
              break;
            case 'score':
              value = player.score;
              break;
            case 'gamesPlayed':
              value = player.gamesPlayed;
              break;
            case 'rank1':
              value = player.rank1;
              break;
            case 'rank2':
              value = player.rank2;
              break;
            case 'rank3':
              value = player.rank3;
              break;
            case 'rank4':
              value = player.rank4;
              break;
            case 'highestScore':
              value = player.highestScore;
              break;
            case 'avoidFourthRate':
              value = player.avoidFourthRate;
              break;
            case 'consecutiveWinRate':
              value = player.consecutiveWinRate;
              break;
            case 'averageRank':
              value = player.averageRank;
              break;
            case 'averageGameScore':
              value = player.averageGameScore;
              break;
            default:
              value = ''; /// 未知键的备用值
          }

          String text;
          switch (col.displayFormat) {
            case 'fixed1':
              text = (value as double).toStringAsFixed(1);
              break;
            case 'percent1':
              text = '${(value as double).toStringAsFixed(1)}%';
              break;
            case 'integer':
              text = (value as int).toString();
              break;
            case 'string':
            default:
              text = value.toString();
              break;
          }
          return DataCell(Text(text));
        }).toList(),
      );
    }).toList();

    return RepaintBoundary(
      key: _playerTableKey,
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
                  columns: columns,
                  rows: rows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRankingTable() {
    if (currentEvent == null) return const SizedBox.shrink();

    final List<DataColumn> columns = currentEvent!.teamColumns
        .where((col) => col.isTeamColumn)
        .map((col) => DataColumn(label: Text(col.columnName)))
        .toList();

    final List<DataRow> rows = teamDf.map((team) {
      return DataRow(
        cells: currentEvent!.teamColumns
            .where((col) => col.isTeamColumn)
            .map((col) {
          dynamic value;
          switch (col.dataKey) {
            case 'name':
              value = team.name;
              break;
            case 'score':
              value = team.score;
              break;
            case 'scoreDifference':
              value = team.scoreDifference;
              break;
            case 'gamesPlayed':
              value = team.gamesPlayed;
              break;
            case 'rank1':
              value = team.rank1;
              break;
            case 'rank2':
              value = team.rank2;
              break;
            case 'rank3':
              value = team.rank3;
              break;
            case 'rank4':
              value = team.rank4;
              break;
            default:
              value = ''; /// 未知键的备用值
          }

          String text;
          switch (col.displayFormat) {
            case 'fixed1':
              text = (value as double).toStringAsFixed(1);
              break;
            case 'percent1':
              text = '${(value as double).toStringAsFixed(1)}%';
              break;
            case 'integer':
              text = (value as int).toString();
              break;
            case 'string':
            default:
              text = value.toString();
              break;
          }
          return DataCell(Text(text));
        }).toList(),
      );
    }).toList();

    return RepaintBoundary(
      key: _teamTableKey,
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
                  columns: columns,
                  rows: rows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateAndUpdate() {
    if (currentEvent == null) {
      _showErrorDialog("请先选择或新建一个赛事。");
      return;
    }

    final int playerCount = currentEvent!.mahjongType == "三人麻将" ? 3 : 4;
    List<Map<String, dynamic>> gameData = [];
    List<String> playerIdsInGame = [];
    int totalRawScore = 0;

    for (int i = 0; i < playerCount; i++) {
      String playerId = _idControllers[i].text.trim();
      String scoreStr = _scoreControllers[i].text.trim();

      if (playerId.isEmpty || scoreStr.isEmpty) {
        continue;
      }

      /// 使用currentEvent的playerBaseData进行查找
      final playerInBase = currentEvent!.playerBaseData.firstWhere(
        (p) => p.mahjongId == playerId,
        orElse: () => Player(name: '', mahjongId: null, team: ''), /// 带有null mahjongId的虚拟玩家
      );

      if (playerInBase.mahjongId == null || playerInBase.mahjongId!.isEmpty) { /// 检查是否返回了虚拟玩家或mahjongId为空
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

    if (gameData.length != playerCount) {
      _showErrorDialog("必须输入 ${playerCount} 名选手的数据。");
      return;
    }
    if (playerIdsInGame.toSet().length != playerCount) {
      _showErrorDialog("错误：一局内的 ${playerCount} 名选手不能重复。");
      return;
    }
    /// 仅针对四人麻将进行团队检查
    /// 确保所有选手都有对应的队伍信息，并且来自不同的队伍
    if (currentEvent!.mahjongType == "四人麻将") {
      final Set<String> teamsInGame = {};
      for (String id in playerIdsInGame) {
        final team = playerToTeam[id];
        if (team == null) {
          _showErrorDialog("错误：选手ID $id 没有对应的队伍信息。");
          return;
        }
        teamsInGame.add(team);
      }
      if (teamsInGame.length != 4) {
        _showErrorDialog("错误：四人麻将一局内的四名选手必须来自不同的队伍。");
        return;
      }
    }
    if (totalRawScore != currentEvent!.scoreCheckTotal) {
      _showErrorDialog("错误：${playerCount} 名选手的场内总分必须为 ${currentEvent!.scoreCheckTotal}，当前为 $totalRawScore。");
      return;
    }

    gameData.sort((a, b) => b['score'].compareTo(a['score']));
    
    List<GameResult> results = [];
    for (int i = 0; i < gameData.length; i++) {
      int rank = i + 1;
      double finalScore = (gameData[i]['score'] - currentEvent!.calculationBasePoint) / 1000 + (currentEvent!.basePoints[rank.toString()] ?? 0.0);
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
      final game = currentEvent!.gameLog.firstWhere((g) => g.gameId == existingGameId);
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
                              /// 更新adjustedResults中的位次
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
                              /// 更新adjustedResults中的最终得分
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
                  DateTime.parse(newDate); /// 验证日期格式
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
    if (currentEvent == null) return;
    final String gameId = uuid.v4();
    final String ts = timestamp ?? DateTime.now().toLocal().toString().split(' ')[0];
    final newLogEntry = GameLogEntry(gameId: gameId, timestamp: ts, results: gameResults);
    currentEvent!.gameLog.add(newLogEntry);
    currentEvent!.gameLog.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));
    await _saveAllEvents(); /// 保存所有赛事，包括更新后的比赛记录
    _showInfoDialog("比赛记录已添加。");
    _recalculateAllStatsFromLog();
    _clearInputFields();
  }

  Future<void> _updateGameInLog(String gameId, List<GameResult> updatedResults, {String? newTimestamp}) async {
    if (currentEvent == null) return;
    final gameIndex = currentEvent!.gameLog.indexWhere((game) => game.gameId == gameId);
    if (gameIndex != -1) {
      currentEvent!.gameLog[gameIndex] = GameLogEntry(
        gameId: gameId,
        timestamp: newTimestamp ?? currentEvent!.gameLog[gameIndex].timestamp,
        results: updatedResults,
      );
      currentEvent!.gameLog.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));
      await _saveAllEvents(); /// 保存所有赛事
      _showInfoDialog("比赛记录已更新。");
      _recalculateAllStatsFromLog();
    } else {
      _showErrorDialog("找不到要更新的比赛记录。");
    }
  }

  void _clearInputFields() {
    final int playerCount = currentEvent?.mahjongType == "三人麻将" ? 3 : 4;
    for (int i = 0; i < playerCount; i++) {
      _idControllers[i].clear();
      _scoreControllers[i].clear();
    }
  }

  void _openEditPlayerWindow() {
    if (currentEvent == null) {
      _showErrorDialog("请先选择或新建一个赛事。");
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlayerManagementDialog(
          currentEvent: currentEvent!,
          showSnackBar: _showSnackBar,
          onRecalculateStats: _recalculateAllStatsFromLog,
          onPrepareCurrentEventData: _prepareCurrentEventData,
          onSaveAllEvents: _saveAllEvents,
        );
      },
    );
  }

  void _openLogManagementWindow() {
    if (currentEvent == null) {
      _showErrorDialog("请先选择或新建一个赛事。");
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GameLogManagementDialog(
          currentEvent: currentEvent!,
          showSnackBar: _showSnackBar,
          showAdjustmentWindow: _showAdjustmentWindow,
          onRecalculateStats: _recalculateAllStatsFromLog,
          onSaveAllEvents: _saveAllEvents,
        );
      },
    );
  }

  void _openAnalysisWindow() {
    if (currentEvent == null) {
      _showErrorDialog("请先选择或新建一个赛事。");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnalysisWindow(
          currentEvent: currentEvent!,
          playerDf: playerDf,
          teamColorMap: teamColorMap,
        );
      },
    );
  }

  List<BarChartGroupData> _getRankDistributionBarData() {
    if (currentEvent == null || playerDf.isEmpty) {
      return [];
    }

    List<BarChartGroupData> barGroups = [];
    final int maxRank = currentEvent!.mahjongType == "三人麻将" ? 3 : 4;

    for (int i = 0; i < playerDf.length; i++) {
      final player = playerDf[i];
      List<BarChartRodData> barRods = [];

      for (int rank = 1; rank <= maxRank; rank++) {
        double rankCount = 0;
        switch (rank) {
          case 1: rankCount = player.rank1.toDouble(); break;
          case 2: rankCount = player.rank2.toDouble(); break;
          case 3: rankCount = player.rank3.toDouble(); break;
          case 4: rankCount = player.rank4.toDouble(); break;
        }

        barRods.add(
          BarChartRodData(
            toY: rankCount,
            color: teamColorMap[player.team]?.withOpacity(rank / maxRank) ?? Colors.grey.withOpacity(rank / maxRank),
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: barRods,
          showingTooltipIndicators: List.generate(maxRank, (index) => index), /// 显示所有排名的工具提示
        ),
      );
    }
    return barGroups;
  }

  List<LineChartBarData> _getScoreTrendLineBarsData() {
    if (currentEvent == null || currentEvent!.gameLog.isEmpty) {
      return [];
    }

    Map<String, List<FlSpot>> playerScoresOverTime = {};
    Map<String, double> currentScores = {};

    /// 初始化所有mahjongId不为null的玩家的当前分数
    for (var player in currentEvent!.playerBaseData) {
      if (player.mahjongId != null) {
        currentScores[player.mahjongId!] = 0.0;
        playerScoresOverTime[player.mahjongId!] = [];
      }
    }

    /// 遍历比赛记录以构建趋势数据
    for (int i = 0; i < currentEvent!.gameLog.length; i++) {
      final game = currentEvent!.gameLog[i];
      for (var result in game.results) {
        currentScores[result.id] = (currentScores[result.id] ?? 0.0) + result.finalScore;
      }
      /// 在每个游戏点为每个玩家添加一个点
      for (var player in currentEvent!.playerBaseData) {
        if (player.mahjongId != null) {
          playerScoresOverTime[player.mahjongId]?.add(FlSpot(i.toDouble(), currentScores[player.mahjongId]!));
        }
      }
    }

    /// 为每个玩家创建LineChartBarData
    return playerScoresOverTime.entries.map((entry) {
      String mahjongId = entry.key; /// 此mahjongId保证来自playerScoresOverTime.entries不为null
      List<FlSpot> spots = entry.value;
      /// 使用非null的mahjongId查找玩家
      Player? player = currentEvent!.playerBaseData.firstWhere((p) => p.mahjongId == mahjongId);

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: teamColorMap[player.team] ?? Colors.grey,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }

  Future<void> _exportGraphicalReport() async {
    _showInfoDialog("正在生成图文报告...");

    try {
      /// 捕获玩家表格
      RenderRepaintBoundary? playerBoundary = _playerTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image? playerImage = await playerBoundary?.toImage(pixelRatio: 2.0); /// 以2倍分辨率捕获
      ByteData? playerByteData = await playerImage?.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? playerBytes = playerByteData?.buffer.asUint8List();

      /// 捕获团队表格
      RenderRepaintBoundary? teamBoundary = _teamTableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image? teamImage = await teamBoundary?.toImage(pixelRatio: 2.0); /// 以2倍分辨率捕获
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

  void _openEventManagementWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventManagementDialog(
          allEvents: allEvents,
          currentEvent: currentEvent,
          onEventSelected: (event) {
            setState(() {
              currentEvent = event;
            });
            _prepareCurrentEventData();
            _recalculateAllStatsFromLog();
          },
          onEventsUpdated: _loadNewEventsData,
          onRecalculateStats: _recalculateAllStatsFromLog,
          onPrepareCurrentEventData: _prepareCurrentEventData,
          showSnackBar: _showSnackBar,
        );
      },
    );
  }
}
