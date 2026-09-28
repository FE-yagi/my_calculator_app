// ver 1.1.0-pwa
import 'package:flutter/material.dart';
import 'data_models.dart';
import 'calculator_logic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '納期計算アプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// パスワード認証とメイン画面を切り替えるラッパーウィジェット
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // 認証状態のフラグ（初期状態は未認証）
  bool _isAuthenticated = false;

  // 正しいパスワード（ここを変更して好きなパスワードに設定可能）
  final String _correctPassword = 'FE2127';

  // パスワード入力用のコントローラー
  final TextEditingController _passwordController = TextEditingController();

  // エラーメッセージ用
  String _errorMessage = '';

  // パスワード確認処理
  void _login() {
    if (_passwordController.text == _correctPassword) {
      setState(() {
        _isAuthenticated = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _errorMessage = 'パスワードが違います';
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 認証済みの場合は納期計算画面を表示
    if (_isAuthenticated) {
      return const DeliveryCalculatorScreen();
    }

    // 未認証の場合はパスワード入力画面を表示
    return Scaffold(
      appBar: AppBar(
        title: const Text('認証画面 ver 1.1.0-pwa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                '納期計算アプリへアクセス',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'パスワードを入力してください',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true, // 入力文字を隠す設定
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'パスワード',
                    prefixIcon: Icon(Icons.key),
                  ),
                  onSubmitted: (_) => _login(),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                height: 48,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ログイン', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
              // バージョン表記
              const Text(
                'ver 1.1.0-pwa',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryCalculatorScreen extends StatefulWidget {
  const DeliveryCalculatorScreen({super.key});

  @override
  State<DeliveryCalculatorScreen> createState() => _DeliveryCalculatorScreenState();
}

class _DeliveryCalculatorScreenState extends State<DeliveryCalculatorScreen> {
  final TextEditingController _codeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  MasterData _masterData = MasterData();
  Set<DateTime> _holidaySet = {};
  bool _isLoading = true;

  CalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final master = await DataLoader.loadMasterData();
    final calendar = await DataLoader.loadCalendarData();
    setState(() {
      _masterData = master;
      _holidaySet = calendar;
      _isLoading = false;
    });
  }

  void _onCalculate() {
    setState(() {
      _result = calculateDelivery(
        code: _codeController.text,
        orderDate: _selectedDate,
        master: _masterData,
        holidaySet: _holidaySet,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _onCalculate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('納期計算アプリ ver 1.1.0-pwa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 受注日選択
                  Card(
                    child: ListTile(
                      title: const Text('受注日'),
                      subtitle: Text(
                        "${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 13桁コード入力
                  TextField(
                    controller: _codeController,
                    maxLength: 13,
                    decoration: const InputDecoration(
                      labelText: '13桁の品番コードを入力',
                      border: OutlineInputBorder(),
                      hintText: '例: ABCDEFG123456',
                    ),
                    onChanged: (_) => _onCalculate(),
                  ),
                  const SizedBox(height: 16),

                  // 計算結果表示領域
                  if (_result != null) ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('【計算結果】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Divider(),
                            _buildResultRow('出荷予定日', _result!.shipDateDisplay, isHeader: true),
                            _buildResultRow('合計所要日数', _result!.totalDisplay),
                            const SizedBox(height: 8),
                            _buildResultRow('機種-口径', '${_result!.modelSize} (${_result!.days1}日)'),
                            _buildResultRow('材質', '${_result!.material} (${_result!.days2}日)'),
                            _buildResultRow('オプション1', '${_result!.opt1} (${_result!.days3}日)'),
                            _buildResultRow('オプション2', '${_result!.opt2} (${_result!.days4}日)'),
                            _buildResultRow('オプション3', '${_result!.opt3} (${_result!.days5}日)'),
                          ],
                        ),
                      ),
                    ),
                    if (_result!.showCatalogMessage)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '※カタログ注意対象機種（ADF/AVP）です。',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isHeader ? 18 : 14, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isHeader ? 20 : 14, fontWeight: FontWeight.bold, color: isHeader ? Colors.blue.shade900 : Colors.black)),
        ],
      ),
    );
  }
}