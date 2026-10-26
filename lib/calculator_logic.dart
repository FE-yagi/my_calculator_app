// ver 1.1.2-pwa
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
  });
}

/// 日本の祝日を判定するヘルパー関数
bool _isJapaneseHoliday(DateTime date) {
  int m = date.month;
  int d = date.day;

  // 固定祝日
  if (m == 1 && d == 1) return true;   // 元日
  if (m == 1 && d == 2) return true;   // 年末年始
  if (m == 1 && d == 3) return true;   // 年末年始
  if (m == 2 && d == 11) return true;  // 建国記念の日
  if (m == 2 && d == 23) return true;  // 天皇誕生日
  if (m == 4 && d == 29) return true;  // 昭和の日
  if (m == 5 && d == 3) return true;   // 憲法記念日
  if (m == 5 && d == 4) return true;   // みどりの日
  if (m == 5 && d == 5) return true;   // こどもの日
  if (m == 8 && d == 11) return true;  // 山の日
  if (m == 11 && d == 3) return true;  // 文化の日
  if (m == 11 && d == 23) return true; // 勤労感謝の日
  if (m == 12 && d == 29) return true; // 年末年始
  if (m == 12 && d == 30) return true; // 年末年始
  if (m == 12 && d == 31) return true; // 年末年始

  // ハッピーマンデー（第N月曜日）の判定用ヘルパー
  bool isNthDayOfWeek(int targetMonth, int weekday, int n) {
    if (date.month != targetMonth || date.weekday != weekday) return false;
    int nth = (date.day - 1) ~/ 7 + 1;
    return nth == n;
  }

  // 成人の日 (1月第2月曜)
  if (isNthDayOfWeek(1, DateTime.monday, 2)) return true;
  // 海の日 (7月第3月曜)
  if (isNthDayOfWeek(7, DateTime.monday, 3)) return true;
  // 敬老の日 (9月第3月曜)
  if (isNthDayOfWeek(9, DateTime.monday, 3)) return true;
  // スポーツの日 (10月第2月曜)
  if (isNthDayOfWeek(10, DateTime.monday, 2)) return true;

  // 春分の日・秋分の日（2026年等の主要な日付を網羅）
  if (m == 3 && (d == 20 || d == 21)) return true; // 春分の日付近
  if (m == 9 && (d == 22 || d == 23)) return true; // 秋分の日付近

  return false;
}

CalculationResult calculateDelivery({
  required String code,
  required DateTime orderDate,
  required MasterData master,
  required Set<DateTime> holidaySet,
}) {
  code = code.trim().toUpperCase();

  if (code.length < 13 || !master.isLoaded) {
    return CalculationResult(
      modelSize: '', material: '', opt1: '', opt2: '', opt3: '',
      days1: '0', days2: '0', days3: '0', days4: '0', days5: '0',
      totalDisplay: '0 日', shipDateDisplay: '-', showCatalogMessage: false,
    );
  }

  // 13桁コード詳細分解
  String mModel = code.substring(0, 3);     // 0〜2文字目 (機種)
  String mFunc = code.substring(3, 5);      // 3〜4文字目 (機能: 2桁)
  String mFlow = code.substring(5, 6);      // 5文字目 (流れ方向)
  String mSize = code.substring(6, 7);      // 6文字目 (口径)
  String mConn = code.substring(7, 8);      // 7文字目 (接続)
  String mStd = code.substring(8, 9);       // 8文字目 (規格)
  String mMaterial = code.substring(9, 10); // 9文字目 (材質)
  String mOpt1 = code.substring(10, 11);    // 10文字目 (付加1)
  String mOpt2 = code.substring(11, 12);    // 11文字目 (付加2)
  String mOpt3 = code.substring(12, 13);    // 12文字目 (付加3)

  // バリデーションチェック
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
      );
    }
  } else {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: '-', opt1: '-', opt2: '-', opt3: '-',
      days1: '-', days2: '-', days3: '-', days4: '-', days5: '-',
      totalDisplay: '型式エラー', shipDateDisplay: '型式エラー', showCatalogMessage: false,
    );
  }

  String days1 = master.sizeMatrix[mModel]?[mSize] ?? 'N';
  String days2 = master.materialMaster[mMaterial] ?? '0';
  String days3 = master.option1Master[mOpt1] ?? '0';
  String days4 = master.option2Master[mOpt2] ?? '0';
  String days5 = master.option3Master[mOpt3] ?? '0';

  List<String> rawList = [days1, days2, days3, days4, days5];
  bool showMsg = mModel.startsWith('ADF') || mModel.startsWith('AVP');

  if (rawList.contains('N')) {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
      days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
      totalDisplay: '制作不可', shipDateDisplay: '制作不可', showCatalogMessage: showMsg,
    );
  }

  if (rawList.contains('Z')) {
    return CalculationResult(
      modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
      days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
      totalDisplay: '工場問合せ', shipDateDisplay: '工場問合せ', showCatalogMessage: showMsg,
    );
  }

  int totalDays = 0;
  for (var valStr in rawList) {
    totalDays += int.tryParse(valStr) ?? 0;
  }

  // 営業日計算（土日・祝日・カレンダー休日を考慮）
  DateTime current = orderDate;
  int addedDays = 0;
  while (addedDays < totalDays) {
    current = current.add(const Duration(days: 1));
    
    // 土日の判定
    if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
      continue;
    }
    
    DateTime dateOnly = DateTime(current.year, current.month, current.day);
    
    // カレンダーファイル（holidaySet）または内部の祝日判定に引っかかったらスキップ
    if (holidaySet.contains(dateOnly) || _isJapaneseHoliday(current)) {
      continue;
    }
    
    addedDays++;
  }

  String shipStr = "${current.year}/${current.month.toString().padLeft(2, '0')}/${current.day.toString().padLeft(2, '0')}";

  return CalculationResult(
    modelSize: '$mModel-$mSize', material: mMaterial, opt1: mOpt1, opt2: mOpt2, opt3: mOpt3,
    days1: days1, days2: days2, days3: days3, days4: days4, days5: days5,
    totalDisplay: '$totalDays 日', shipDateDisplay: shipStr, showCatalogMessage: showMsg,
  );
}