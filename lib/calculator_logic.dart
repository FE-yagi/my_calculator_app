// ver 2.3.13-pwa
import 'data_models.dart';

class CalculationResult {
  final String modelSize;
  final String material;
  final String opt1;
  final String opt2;
  final String opt3;
  final String days1;
  final String days2;
  final String days3;
  final String days4;
  final String days5;
  final String totalDisplay;
  final String shipDateDisplay;
  final bool showCatalogMessage;
  final String catalogMessage;

  CalculationResult({
    required this.modelSize,
    required this.material,
    required this.opt1,
    required this.opt2,
    required this.opt3,
    required this.days1,
    required this.days2,
    required this.days3,
    required this.days4,
    required this.days5,
    required this.totalDisplay,
    required this.shipDateDisplay,
    required this.showCatalogMessage,
    required this.catalogMessage,
  });
}

/// 日本の祝日を判定するヘルパー関数
bool _isJapaneseHoliday(DateTime date) {
  int m = date.month;
  int d = date.day;

  if (m == 1 && d == 1) return true;
  if (m == 1 && d == 2) return true;
  if (m == 1 && d == 3) return true;
  if (m == 2 && d == 11) return true;
  if (m == 2 && d == 23) return true;
  if (m == 4 && d == 29) return true;
  if (m == 5 && d == 3) return true;
  if (m == 5 && d == 4) return true;
  if (m == 5 && d == 5) return true;
  if (m == 8 && d == 11) return true;
  if (m == 11 && d == 3) return true;
  if (m == 11 && d == 23) return true;
  if (m == 12 && d == 29) return true;
  if (m == 12 && d == 30) return true;
  if (m == 12 && d == 31) return true;

  bool isNthDayOfWeek(int targetMonth, int weekday, int n) {
    if (date.month != targetMonth || date.weekday != weekday) return false;
    int nth = (date.day - 1) ~/ 7 + 1;
    return nth == n;
  }

  if (isNthDayOfWeek(1, DateTime.monday, 2)) return true;
  if (isNthDayOfWeek(7, DateTime.monday, 3)) return true;
  if (isNthDayOfWeek(9, DateTime.monday, 3)) return true;
  if (isNthDayOfWeek(10, DateTime.monday, 2)) return true;

  if (m == 3 && (d == 20 || d == 21)) return true;
  if (m == 9 && (d == 22 || d == 23)) return true;

  return false;
}

CalculationResult calculateDelivery({
  required String code,
  required DateTime orderDate,
  required MasterData master,
  required Set<DateTime> holidaySet,
  String fluidType = 'H2O',
  double maxFlow = 5.0,
  String flowUnit = 'L/min',
}) {
  code = code.trim().toUpperCase();

  if (code.length < 13 || !master.isLoaded) {
    return CalculationResult(
      modelSize: '', material: '', opt1: '', opt2: '', opt3: '',
      days1: '0', days2: '0', days3: '0', days4: '0', days5: '0',
      totalDisplay: '0 日', shipDateDisplay: '-', showCatalogMessage: false,
      catalogMessage: '',
    );
  }

  String mModel = code.substring(0, 3);
  String mFunc = code.substring(3, 5);
  String mFlow = code.substring(5, 6);
  String mSize = code.substring(6, 7);
  String mConn = code.substring(7, 8);
  String mStd = code.substring(8, 9);
  String mMaterial = code.substring(9, 10);
  String mOpt1 = code.substring(10, 11);
  String mOpt2 = code.substring(11, 12);
  String mOpt3 = code.substring(12, 13);

  if (master.validationRules.containsKey(mModel)) {
    var rule = master.validationRules[mModel]!;
    bool isError = false;

    if (rule.functions.isNotEmpty && !rule.functions.contains(mFunc)) isError = true;
    if (rule.flowDirections.isNotEmpty && !rule.flowDirections.contains(mFlow)) isError = true;
    if (rule.sizes.isNotEmpty && !rule.sizes.contains(mSize)) isError = true;
    if (rule.connections.isNotEmpty && !rule.connections.contains(mConn)) isError = true;
    if (rule.standards.isNotEmpty && !rule.standards.contains(mStd)) isError = true;
    if (rule.materials.isNotEmpty && !rule.materials.contains(mMaterial)) isError = true;
    if (rule.option1s.isNotEmpty && !rule.option1s.contains(mOpt1)) isError = true;
    if (rule.option2s.isNotEmpty && !rule.option2s.contains(mOpt2)) isError = true;
    if (rule.option3s.isNotEmpty && !rule.option3s.contains(mOpt3)) isError = true;

    if (isError) {
      return CalculationResult(
        modelSize: '$mModel-$mSize', material: '-', opt1: '-', opt2: '-', opt3: '-',
        days1: '-', days2: '-', days3: '-', days4: '-', days5: '-',
        totalDisplay: '型式エラー', shipDateDisplay: '型式エラー', showCatalogMessage: false,
        catalogMessage: '',
      );
    }
  } else {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: '-', opt1: '-', opt2: '-', opt3: '-',
      days1: '-', days2: '-', days3: '-', days4: '-', days5: '-',
      totalDisplay: '型式エラー', shipDateDisplay: '型式エラー', showCatalogMessage: false,
      catalogMessage: '',
    );
  }

  String days1 = master.sizeMatrix[mModel]?[mSize] ?? 'N';
  String days2 = master.materialMaster[mMaterial] ?? '0';
  String days3 = master.option1Master[mOpt1] ?? '0';
  String days4 = master.option2Master[mOpt2] ?? '0';
  String days5 = master.option3Master[mOpt3] ?? '0';

  List<String> rawList = [days1, days2, days3, days4, days5];
  bool isAdcAvp = mModel.startsWith('ADF') || mModel.startsWith('AVP');

  if (rawList.contains('N')) {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
      days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
      totalDisplay: '制作不可', shipDateDisplay: '制作不可', showCatalogMessage: isAdcAvp,
      catalogMessage: isAdcAvp ? 'カタログを確認して◎は上記納期、〇は+10稼働日、-は制作不可。' : '',
    );
  }

  if (rawList.contains('Z')) {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
      days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
      totalDisplay: '工場問合せ', shipDateDisplay: '工場問合せ', showCatalogMessage: isAdcAvp,
      catalogMessage: isAdcAvp ? 'カタログを確認して◎は上記納期、〇は+10稼働日、-は制作不可。' : '',
    );
  }

  int baseDays = 0;
  for (var valStr in rawList) {
    baseDays += int.tryParse(valStr) ?? 0;
  }

  int catalogAddDays = 0;
  bool isOutOfRange = false;

  if (isAdcAvp) {
    if (fluidType != 'H2O') {
      return CalculationResult(
        modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
        days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
        totalDisplay: '工場問合せ', shipDateDisplay: '工場問合せ', showCatalogMessage: true,
        catalogMessage: 'カタログを確認して◎は上記納期、〇は+10稼働日、-は制作不可。',
      );
    } else {
      var catalogList = (mModel.startsWith('ADF')) ? master.adfCatalog : master.avpCatalog;
      String matchedSymbol = '-';
      bool foundRange = false;

      // 口径コード（例: 'E' など）をカタログの列キー（'1', '2', '3', '4'）に変換するマッピング
      // ADFの場合、サイズ 'E' は通常 1番目の口径（'1'）に対応
      String catalogSizeKey = '1';
      if (mSize == 'E') {
        catalogSizeKey = '1';
      } else if (mSize == 'F' || mSize == 'H') { // 必要に応じて他のサイズ文字の対応も追加可能
        catalogSizeKey = '2';
      } else {
        // デフォルトとして mSize をそのまま試すか、数値ならそのまま使う
        catalogSizeKey = mSize;
      }

      for (var row in catalogList) {
        if (row.unit == flowUnit && maxFlow >= row.minFlow && maxFlow <= row.maxFlow) {
          foundRange = true;
          matchedSymbol = row.sizeSymbols[catalogSizeKey] ?? '-';
          break;
        }
      }

      if (!foundRange || matchedSymbol == '-') {
        isOutOfRange = true;
      } else if (matchedSymbol == '〇') {
        catalogAddDays = 10;
      } else if (matchedSymbol == '◎') {
        catalogAddDays = 0;
      }
    }
  }

  int totalDays = baseDays + catalogAddDays;

  if (isOutOfRange) {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
      days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
      totalDisplay: '流量範囲外(制作不可)', shipDateDisplay: '流量範囲外(制作不可)', showCatalogMessage: true,
      catalogMessage: 'カタログを確認して◎は上記納期、〇は+10稼働日、-は制作不可。',
    );
  }

  DateTime current = orderDate;
  int addedDays = 0;
  while (addedDays < totalDays) {
    current = current.add(const Duration(days: 1));
    
    if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
      continue;
    }
    
    DateTime dateOnly = DateTime(current.year, current.month, current.day);
    
    if (holidaySet.contains(dateOnly) || _isJapaneseHoliday(current)) {
      continue;
    }
    
    addedDays++;
  }

  String shipStr = "${current.year}/${current.month.toString().padLeft(2, '0')}/${current.day.toString().padLeft(2, '0')}";

  return CalculationResult(
    modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
    days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
    totalDisplay: '$totalDays 日', shipDateDisplay: shipStr, showCatalogMessage: isAdcAvp,
    catalogMessage: isAdcAvp ? 'カタログを確認して◎は上記納期、〇は+10稼働日、-は制作不可。' : '',
  );
}