import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; // For web-specific functionalities like downloading files
import 'package:http/http.dart' as http;

import '../models/event.dart';
import '../models/column_config.dart';
import 'column_config_dialog.dart'; // Import the new ColumnConfigDialog

class EventManagementDialog extends StatefulWidget {
  final List<Event> allEvents;
  final Event? currentEvent;
  final Function(Event?) onEventSelected;
  final Function(List<Event>) onEventsUpdated;
  final Function() onRecalculateStats;
  final Function() onPrepareCurrentEventData;
  final Function(String message, {bool isError}) showSnackBar;

  const EventManagementDialog({
    super.key,
    required this.allEvents,
    required this.currentEvent,
    required this.onEventSelected,
    required this.onEventsUpdated,
    required this.onRecalculateStats,
    required this.onPrepareCurrentEventData,
    required this.showSnackBar,
  });

  @override
  State<EventManagementDialog> createState() => _EventManagementDialogState();
}

class _EventManagementDialogState extends State<EventManagementDialog> {
  final Uuid uuid = const Uuid();

  Future<void> _saveAllEvents() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(widget.allEvents.map((e) => e.toJson()).toList());
      await prefs.setString('all_events', jsonString);
    } catch (e) {
      widget.showSnackBar("无法保存赛事数据: $e", isError: true);
    }
  }

  Future<void> _showEditEventDialog(Event eventToEdit) async {
    final TextEditingController eventNameController = TextEditingController(text: eventToEdit.eventName);
    String? selectedMahjongType = eventToEdit.mahjongType;
    bool _isTeamEvent = eventToEdit.isTeamEvent; // Track team event status
    final TextEditingController scoreCheckTotalController = TextEditingController(text: eventToEdit.scoreCheckTotal.toString());
    final TextEditingController calculationBasePointController = TextEditingController(text: eventToEdit.calculationBasePoint.toString());
    final Map<String, TextEditingController> basePointControllers = {
      '1': TextEditingController(text: eventToEdit.basePoints['1']?.toStringAsFixed(1) ?? '0.0'),
      '2': TextEditingController(text: eventToEdit.basePoints['2']?.toStringAsFixed(1) ?? '0.0'),
      '3': TextEditingController(text: eventToEdit.basePoints['3']?.toStringAsFixed(1) ?? '0.0'),
      '4': TextEditingController(text: eventToEdit.basePoints['4']?.toStringAsFixed(1) ?? '0.0'),
    };

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("编辑赛事配置"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Update default values if mahjong type changes
              if (selectedMahjongType == "三人麻将" && basePointControllers.containsKey('4')) {
                basePointControllers.remove('4');
              } else if (selectedMahjongType == "四人麻将" && !basePointControllers.containsKey('4')) {
                basePointControllers['4'] = TextEditingController(text: '-30.0');
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventNameController,
                      decoration: const InputDecoration(labelText: "赛事名称"),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedMahjongType,
                      decoration: const InputDecoration(labelText: "麻将类型"),
                      items: <String>['四人麻将', '三人麻将']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMahjongType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('赛事类型', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('团队赛事'),
                            value: true,
                            groupValue: _isTeamEvent,
                            onChanged: (bool? value) {
                              setState(() {
                                _isTeamEvent = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('个人赛事'),
                            value: false,
                            groupValue: _isTeamEvent,
                            onChanged: (bool? value) {
                              setState(() {
                                _isTeamEvent = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('计分规则设置', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: scoreCheckTotalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '总分检查 (${selectedMahjongType == "四人麻将" ? "四人" : "三人"}场内总分)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: calculationBasePointController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '精算原点'),
                    ),
                    const SizedBox(height: 10),
                    Text('顺位点数设置:', style: Theme.of(context).textTheme.titleSmall),
                    if (selectedMahjongType == "四人麻将") ...[
                      _buildBasePointInput(context, '1位', basePointControllers['1']!),
                      _buildBasePointInput(context, '2位', basePointControllers['2']!),
                      _buildBasePointInput(context, '3位', basePointControllers['3']!),
                      _buildBasePointInput(context, '4位', basePointControllers['4']!),
                    ] else if (selectedMahjongType == "三人麻将") ...[
                      _buildBasePointInput(context, '1位', basePointControllers['1']!),
                      _buildBasePointInput(context, '2位', basePointControllers['2']!),
                      _buildBasePointInput(context, '3位', basePointControllers['3']!),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("保存"),
              onPressed: () async {
                if (eventNameController.text.trim().isEmpty) {
                  widget.showSnackBar("赛事名称不能为空。", isError: true);
                  return;
                }

                final int? parsedScoreCheckTotal = int.tryParse(scoreCheckTotalController.text.trim());
                if (parsedScoreCheckTotal == null) {
                  widget.showSnackBar("总分检查必须是有效数字。", isError: true);
                  return;
                }

                final int? parsedCalculationBasePoint = int.tryParse(calculationBasePointController.text.trim());
                if (parsedCalculationBasePoint == null) {
                  widget.showSnackBar("精算原点必须是有效数字。", isError: true);
                  return;
                }

                final Map<String, double> parsedBasePoints = {};
                for (var entry in basePointControllers.entries) {
                  final double? value = double.tryParse(entry.value.text.trim());
                  if (value == null) {
                    widget.showSnackBar("顺位点数 '${entry.key}' 必须是有效数字。", isError: true);
                    return;
                  }
                  parsedBasePoints[entry.key] = value;
                }

                // Update the existing event object
                setState(() {
                  eventToEdit.eventName = eventNameController.text.trim();
                  eventToEdit.mahjongType = selectedMahjongType!;
                  eventToEdit.isTeamEvent = _isTeamEvent; // Update isTeamEvent
                  eventToEdit.scoreCheckTotal = parsedScoreCheckTotal;
                  eventToEdit.calculationBasePoint = parsedCalculationBasePoint;
                  eventToEdit.basePoints = parsedBasePoints;
                  // Update columns if mahjong type changed
                  if (eventToEdit.mahjongType == "三人麻将" && eventToEdit.playerColumns.length == 4) {
                    eventToEdit.playerColumns = Event.defaultThreePlayerEvent(eventId: '', eventName: '').playerColumns;
                    eventToEdit.teamColumns = Event.defaultThreePlayerEvent(eventId: '', eventName: '').teamColumns;
                  } else if (eventToEdit.mahjongType == "四人麻将" && eventToEdit.playerColumns.length == 3) {
                    eventToEdit.playerColumns = Event.defaultFourPlayerEvent(eventId: '', eventName: '').playerColumns;
                    eventToEdit.teamColumns = Event.defaultFourPlayerEvent(eventId: '', eventName: '').teamColumns;
                  }
                  // If it's a personal event, clear team columns
                  if (!_isTeamEvent) {
                    eventToEdit.teamColumns = [];
                  }
                });

                await _saveAllEvents();
                widget.showSnackBar("赛事 “${eventToEdit.eventName}” 已更新。");
                widget.onRecalculateStats();
                Navigator.of(context).pop(); // Close edit event dialog
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

  Future<void> _showNewEventDialog() async {
    final TextEditingController eventNameController = TextEditingController();
    String? selectedMahjongType = "四人麻将"; // Default to 4-player
    bool _isTeamEvent = true; // Default to team event for new events
    final TextEditingController scoreCheckTotalController = TextEditingController(text: "100000");
    final TextEditingController calculationBasePointController = TextEditingController(text: "30000");
    final Map<String, TextEditingController> basePointControllers = {
      '1': TextEditingController(text: '50.0'),
      '2': TextEditingController(text: '10.0'),
      '3': TextEditingController(text: '-10.0'),
      '4': TextEditingController(text: '-30.0'),
    };

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("新建赛事"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Update default values if mahjong type changes
              if (selectedMahjongType == "三人麻将" && scoreCheckTotalController.text == "100000") {
                scoreCheckTotalController.text = "75000";
                basePointControllers['1']?.text = '45.0';
                basePointControllers['2']?.text = '0.0';
                basePointControllers['3']?.text = '-45.0';
                basePointControllers.remove('4');
              } else if (selectedMahjongType == "四人麻将" && scoreCheckTotalController.text == "75000") {
                scoreCheckTotalController.text = "100000";
                basePointControllers['1']?.text = '50.0';
                basePointControllers['2']?.text = '10.0';
                basePointControllers['3']?.text = '-10.0';
                basePointControllers['4'] = TextEditingController(text: '-30.0');
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventNameController,
                      decoration: const InputDecoration(labelText: "赛事名称"),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedMahjongType,
                      decoration: const InputDecoration(labelText: "麻将类型"),
                      items: <String>['四人麻将', '三人麻将']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMahjongType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('赛事类型', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('团队赛事'),
                            value: true,
                            groupValue: _isTeamEvent,
                            onChanged: (bool? value) {
                              setState(() {
                                _isTeamEvent = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('个人赛事'),
                            value: false,
                            groupValue: _isTeamEvent,
                            onChanged: (bool? value) {
                              setState(() {
                                _isTeamEvent = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('计分规则设置', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: scoreCheckTotalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '总分检查 (${selectedMahjongType == "四人麻将" ? "四人" : "三人"}场内总分)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: calculationBasePointController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '精算原点'),
                    ),
                    const SizedBox(height: 10),
                    Text('顺位点数设置:', style: Theme.of(context).textTheme.titleSmall),
                    if (selectedMahjongType == "四人麻将") ...[
                      _buildBasePointInput(context, '1位', basePointControllers['1']!),
                      _buildBasePointInput(context, '2位', basePointControllers['2']!),
                      _buildBasePointInput(context, '3位', basePointControllers['3']!),
                      _buildBasePointInput(context, '4位', basePointControllers['4']!),
                    ] else if (selectedMahjongType == "三人麻将") ...[
                      _buildBasePointInput(context, '1位', basePointControllers['1']!),
                      _buildBasePointInput(context, '2位', basePointControllers['2']!),
                      _buildBasePointInput(context, '3位', basePointControllers['3']!),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("创建"),
              onPressed: () async { // Mark as async
                if (eventNameController.text.trim().isEmpty) {
                  widget.showSnackBar("赛事名称不能为空。", isError: true);
                  return;
                }

                final int? parsedScoreCheckTotal = int.tryParse(scoreCheckTotalController.text.trim());
                if (parsedScoreCheckTotal == null) {
                  widget.showSnackBar("总分检查必须是有效数字。", isError: true);
                  return;
                }

                final int? parsedCalculationBasePoint = int.tryParse(calculationBasePointController.text.trim());
                if (parsedCalculationBasePoint == null) {
                  widget.showSnackBar("精算原点必须是有效数字。", isError: true);
                  return;
                }

                final Map<String, double> parsedBasePoints = {};
                for (var entry in basePointControllers.entries) {
                  final double? value = double.tryParse(entry.value.text.trim());
                  if (value == null) {
                    widget.showSnackBar("顺位点数 '${entry.key}' 必须是有效数字。", isError: true);
                    return;
                  }
                  parsedBasePoints[entry.key] = value;
                }

                final String newEventId = uuid.v4();
                Event newEvent; // Declare newEvent here
                if (selectedMahjongType == "三人麻将") {
                  newEvent = Event(
                    eventId: newEventId,
                    eventName: eventNameController.text.trim(),
                    mahjongType: selectedMahjongType!,
                    isTeamEvent: _isTeamEvent, // Pass the selected team event status
                    scoreCheckTotal: parsedScoreCheckTotal,
                    calculationBasePoint: parsedCalculationBasePoint,
                    basePoints: parsedBasePoints,
                    playerColumns: Event.defaultThreePlayerEvent(eventId: '', eventName: '').playerColumns,
                    teamColumns: _isTeamEvent ? Event.defaultThreePlayerEvent(eventId: '', eventName: '').teamColumns : [], // Clear team columns if not a team event
                    playerBaseData: [],
                    gameLog: [],
                  );
                } else {
                  newEvent = Event(
                    eventId: newEventId,
                    eventName: eventNameController.text.trim(),
                    mahjongType: selectedMahjongType!,
                    isTeamEvent: _isTeamEvent, // Pass the selected team event status
                    scoreCheckTotal: parsedScoreCheckTotal,
                    calculationBasePoint: parsedCalculationBasePoint,
                    basePoints: parsedBasePoints,
                    playerColumns: Event.defaultFourPlayerEvent(eventId: '', eventName: '').playerColumns,
                    teamColumns: _isTeamEvent ? Event.defaultFourPlayerEvent(eventId: '', eventName: '').teamColumns : [], // Clear team columns if not a team event
                    playerBaseData: [],
                    gameLog: [],
                  );
                }

                widget.allEvents.add(newEvent);
                widget.onEventSelected(newEvent); // Notify parent to set current event
                widget.onEventsUpdated(widget.allEvents); // Notify parent to update allEvents
                widget.onPrepareCurrentEventData();
                await _saveAllEvents();
                widget.showSnackBar("赛事 “${newEvent.eventName}” 已创建。");
                widget.onRecalculateStats();
                Navigator.of(context).pop(); // Close new event dialog
                Navigator.of(context).pop(); // Close event management dialog
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

  Future<void> _importEventsFromFile() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json'; // Accept only JSON files
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        reader.onLoadEnd.listen((e) async {
          try {
            final String jsonString = reader.result as String;
            final List<dynamic> jsonList = json.decode(jsonString);
            final List<Event> importedEvents = jsonList.map((e) => Event.fromJson(e)).toList();

            if (importedEvents.isEmpty) {
              widget.showSnackBar("导入的文件不包含任何赛事数据。", isError: true);
              return;
            }

            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("确认导入"),
                  content: const Text("这将用文件中的数据覆盖所有当前赛事数据。\n此操作无法撤销。是否继续？"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text("覆盖并导入"),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              widget.onEventsUpdated(importedEvents); // This will now trigger the centralized update logic in main.dart
              widget.showSnackBar("所有赛事数据已从文件成功导入。");
              Navigator.of(context).pop(); // Close the event management dialog
            }
          } catch (err) {
            widget.showSnackBar("导入失败：文件格式无效或内容损坏。 $err", isError: true);
          }
        });
      }
    });
  }

  Widget _buildBasePointInput(BuildContext context, String rankLabel, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('$rankLabel:'),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("赛事管理"),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.allEvents.length,
                    itemBuilder: (context, index) {
                      final event = widget.allEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(event.eventName),
                          subtitle: Text('类型: ${event.mahjongType} | 选手数: ${event.playerBaseData.length} | 比赛数: ${event.gameLog.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  // Show the edit dialog on top of the current one
                                  await _showEditEventDialog(event);
                                  // After the dialog is closed, the list might have changed, so rebuild the state.
                                  setState(() {});
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
                                        content: Text("确定要永久删除赛事 “${event.eventName}” 吗？\n此操作无法撤销。"),
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
                                    String eventIdToRemove = event.eventId;
                                    bool wasCurrentEvent = widget.currentEvent?.eventId == eventIdToRemove;

                                    setState(() {
                                      widget.allEvents.removeWhere((e) => e.eventId == eventIdToRemove);
                                      if (wasCurrentEvent) {
                                        Event? newCurrentEvent = widget.allEvents.isNotEmpty ? widget.allEvents.first : null;
                                        widget.onEventSelected(newCurrentEvent);
                                      }
                                    });

                                    await _saveAllEvents();
                                    widget.showSnackBar("赛事已删除。");
                                    widget.onRecalculateStats();
                                    // No need to pop and reopen, setState will rebuild the list.
                                  }
                                },
                              ),
                              Radio<Event>(
                                value: event,
                                groupValue: widget.currentEvent,
                                onChanged: (Event? value) async {
                                  if (value != null) {
                                    widget.onEventSelected(value); // Notify parent to set current event
                                    widget.onPrepareCurrentEventData();
                                    widget.onRecalculateStats();
                                    await _saveAllEvents();
                                    Navigator.of(context).pop(); // Close dialog after selection
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close current dialog
                    _showNewEventDialog();
                  },
                  child: const Text("新建赛事"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _importEventsFromFile();
                  },
                  child: const Text("从文件导入赛事"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close current dialog
                    if (widget.currentEvent != null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ColumnConfigDialog(
                            currentEvent: widget.currentEvent!,
                            showSnackBar: widget.showSnackBar,
                            onRecalculateStats: widget.onRecalculateStats,
                            onSaveAllEvents: _saveAllEvents, // Use local _saveAllEvents
                            openEventManagementWindow: () { // Pass a function to reopen EventManagementDialog
                              showDialog(
                                context: context, // Use the current context
                                builder: (context) => EventManagementDialog(
                                  allEvents: widget.allEvents,
                                  currentEvent: widget.currentEvent,
                                  onEventSelected: widget.onEventSelected,
                                  onEventsUpdated: widget.onEventsUpdated,
                                  onRecalculateStats: widget.onRecalculateStats,
                                  onPrepareCurrentEventData: widget.onPrepareCurrentEventData,
                                  showSnackBar: widget.showSnackBar,
                                ),
                              );
                            },
                          );
                        },
                      );
                    } else {
                      widget.showSnackBar("请先选择一个赛事来配置表格列。", isError: true);
                    }
                  },
                  child: const Text("配置表格列"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.allEvents.isEmpty) {
                      widget.showSnackBar("没有赛事数据可供导出。", isError: true);
                      return;
                    }
                    final String jsonString = json.encode(widget.allEvents.map((e) => e.toJson()).toList());
                    final blob = html.Blob([jsonString], 'application/json');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    final anchor = html.AnchorElement(href: url)
                      ..setAttribute("download", "majhong_events_backup.json")
                      ..click();
                    html.Url.revokeObjectUrl(url);
                    widget.showSnackBar("所有赛事数据已导出为JSON文件。");
                  },
                  child: const Text("导出所有赛事为JSON"),
                ),
              ],
            ),
          );
        },
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
