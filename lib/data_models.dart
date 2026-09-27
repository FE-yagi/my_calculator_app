// ver 1.0.0
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MasterData {
  bool isLoaded = false;
  Map<String, Map<String, String>> sizeMatrix = {};
  Map<String, String> materialMaster = {};
  Map<String, String> option1Master = {};
  Map<String, String> option2Master = {};
  Map<String, String> option3Master = {};
}

class DataLoader {
  static Future<MasterData> loadMasterData() async {
    final master = MasterData();
    try {
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