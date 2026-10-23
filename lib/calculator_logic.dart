// ver 1.1.0
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
  String mModel = code.substring(0, 3);
  String mFunc = code.substring(3, 2);
  String mFlow = code.substring(5, 1);
  String mSize = code.substring(6, 1);
  String mConn = code.substring(7, 1);
  String mStd = code.substring(8, 1);
  String mMaterial = code.substring(9, 1);
  String mOpt1 = code.substring(10, 1);
  String mOpt2 = code.substring(11, 1);
  String mOpt3 = code.substring(12, 1);

  // バリデーションチェック（master2ルール検証）
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
    // 機種自体が存在しない場合
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

  // 営業日計算
  DateTime current = orderDate;
  int addedDays = 0;
  while (addedDays < totalDays) {
    current = current.add(const Duration(days: 1));
    if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
      continue;
    }
    DateTime dateOnly = DateTime(current.year, current.month, current.day);
    if (holidaySet.contains(dateOnly)) {
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