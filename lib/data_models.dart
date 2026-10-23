// ver 1.1.0
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// 型式バリデーションルールを保持するクラス
class ModelValidationRule {
  Set<String> functions = {};
  Set<String> flowDirections = {};
  Set<String> sizes = {};
  Set<String> connections = {};
  Set<String> standards = {};
  Set<String> materials = {};
  Set<String> option1s = {};
  Set<String> option2s = {};
  Set<String> option3s = {};
}

class MasterData {
  bool isLoaded = false;
  Map<String, Map<String, String>> sizeMatrix = {};
  Map<String, String> materialMaster = {};
  Map<String, String> option1Master = {};
  Map<String, String> option2Master = {};
  Map<String, String> option3Master = {};
  
  // バリデーションルール用のマップ
  Map<String, ModelValidationRule> validationRules = {};
}

class DataLoader {
  static Future<MasterData> loadMasterData() async {
    final master = MasterData();
    try {
      // 1. master.dat の読み込み
      final content = await rootBundle.loadString('assets/master.dat');
      final lines = LineSplitter.split(content);

      String currentSection = '';
      for (var line in lines) {
        var trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          currentSection = trimmed.substring(1, trimmed.length - 1);
          continue;
        }

        var parts = trimmed.split('=');
        if (parts.length < 2) continue;

        var key = parts[0].trim().toUpperCase();
        var val = parts[1].trim().toUpperCase();

        switch (currentSection) {
          case 'SizeMatrix':
            var subParts = key.split('-');
            if (subParts.length == 2) {
              var modelKey = subParts[0];
              var sizeKey = subParts[1];
              master.sizeMatrix.putIfAbsent(modelKey, () => {});
              master.sizeMatrix[modelKey]![sizeKey] = val;
            }
            break;
          case 'Material':
            master.materialMaster[key] = val;
            break;
          case 'Option1':
            master.option1Master[key] = val;
            break;
          case 'Option2':
            master.option2Master[key] = val;
            break;
          case 'Option3':
            master.option3Master[key] = val;
            break;
        }
      }

      // 2. master2.dat の読み込み（バリデーションルール）
      try {
        final content2 = await rootBundle.loadString('assets/master2.dat');
        final lines2 = LineSplitter.split(content2);
        ModelValidationRule? currentRule;

        for (var line in lines2) {
          var trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          if (trimmed.startsWith('機種:')) {
            var modelName = trimmed.substring(3).trim().toUpperCase();
            currentRule = ModelValidationRule();
            master.validationRules[modelName] = currentRule;
          } else if (currentRule != null && trimmed.contains(':')) {
            var idx = trimmed.indexOf(':');
            var itemKey = trimmed.substring(0, idx).trim();
            var itemVals = trimmed.substring(idx + 1).trim();
            var valArray = itemVals.split(',');

            for (var v in valArray) {
              var cleanV = v.trim();
              if (itemKey == '機能') currentRule.functions.add(cleanV);
              if (itemKey == '流れ方向') currentRule.flowDirections.add(cleanV);
              if (itemKey == '口径') currentRule.sizes.add(cleanV);
              if (itemKey == '接続') currentRule.connections.add(cleanV);
              if (itemKey == '規格') currentRule.standards.add(cleanV);
              if (itemKey == '材質') currentRule.materials.add(cleanV);
              if (itemKey == '付加１' || itemKey == '付加1') currentRule.option1s.add(cleanV);
              if (itemKey == '付加２' || itemKey == '付加2') currentRule.option2s.add(cleanV);
              if (itemKey == '付加３' || itemKey == '付加3') currentRule.option3s.add(cleanV);
            }
          }
        }
      } catch (_) {}

      master.isLoaded = true;
    } catch (e) {
      master.isLoaded = false;
    }
    return master;
  }

  static Future<Set<DateTime>> loadCalendarData() async {
    final holidaySet = <DateTime>{};
    try {
      final content = await rootBundle.loadString('assets/calendar.dat');
      final lines = LineSplitter.split(content);

      for (var line in lines) {
        var trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        try {
          var dt = DateTime.parse(trimmed.replaceAll('/', '-'));
          holidaySet.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
    } catch (e) {
      // エラー時は空セット
    }
    return holidaySet;
  }
}