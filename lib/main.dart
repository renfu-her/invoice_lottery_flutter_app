import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:invoice_lottery/utils/privacy_policy.dart';
import 'package:invoice_lottery/utils/splash_screen.dart';

Dio dio = Dio();
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '查詢發票中奬號碼',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> years = [];
  List<String> months = [];
  String? selectedYear;
  String? selectedMonth;
  List<dynamic> apiData = [];
  String qrData = '';
  String matchResult = '';

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isCameraStopped = false;

  @override
  void initState() {
    super.initState();
    _fetchYearsAndMonths();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("查詢發票中奬號碼")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: selectedYear,
              onChanged: (newValue) {
                setState(() {
                  selectedYear = newValue!;
                });
              },
              items: years.map((year) {
                return DropdownMenuItem<String>(
                  child: Text(year, style: const TextStyle(fontSize: 18)),
                  value: year,
                );
              }).toList(),
              hint: const Text("年份"),
            ),
            const SizedBox(height: 5),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedMonth,
              onChanged: (newValue) {
                setState(() {
                  selectedMonth = newValue!;
                });
              },
              items: months.map((month) {
                return DropdownMenuItem<String>(
                  child: Text(month, style: const TextStyle(fontSize: 18)),
                  value: month,
                );
              }).toList(),
              hint: const Text("月份"),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text("查 詢", style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: SingleChildScrollView(
                child: _buildCustomTable(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String? scannedData = await _scanQR();
                setState(() {
                  qrData = scannedData ?? '';
                  matchResult = _matchQRData(qrData);
                });
              },
              child: const Text("掃描二維碼", style: TextStyle(fontSize: 22)),
            ),
            Text('掃描結果: $qrData', style: const TextStyle(fontSize: 22)),
            Text(
              '比對結果: $matchResult',
              style: TextStyle(
                  color: matchResult == '中奬' ? Colors.green : Colors.red,
                  fontSize: 26),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.lightBlueAccent, // 或其他你想要的背景色
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyPage()));
              },
              child: const Text(
                "隱私權政策",
                style: TextStyle(
                  color: Colors.white, // 將其顏色設定為藍色使其看起來像一個連結
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTable() {
    List<Widget> tableRows = [];

    // 第一行，中奬說明與中奬號碼
    tableRows.add(
      const Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '中奬說明',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: Center(
                child: Text(
              '中奬號碼',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            )),
          ),
        ],
      ),
    );

    for (var item in apiData) {
      // 特別奬是全部紅色的
      tableRows.add(_buildRow("特別奬", item['special_bonus'], isAllRed: true));
      tableRows.add(_buildRow("特奬", item['special_award']));
      tableRows.add(_buildRow("頭奬", item['jackpot']));
    }

    return Column(children: tableRows);
  }

  // 更新 _buildRow 方法來包含 isAllRed 參數
  Widget _buildRow(String title, String data, {bool isAllRed = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // 使Row的子项垂直居中
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 使Column的子项垂直居中
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold), // 放大字体并加粗
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 這裡使號碼垂直居中
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    ...data.split('、').map((number) {
                      if (isAllRed) {
                        return TextSpan(
                          text: number, // 每個號碼後面都加一個換行符，使號碼在不同的行上
                          style:
                              const TextStyle(color: Colors.red, fontSize: 18),
                        );
                      }
                      return TextSpan(
                        text: '\n' + number.substring(0, number.length - 3),
                        style: const TextStyle(fontSize: 18),
                        children: [
                          TextSpan(
                            text: number.substring(number.length - 3) +
                                '\n', // 在每3位後面都加一個換行符
                            style: const TextStyle(
                                color: Colors.red, fontSize: 18),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _fetchYearsAndMonths() async {
    try {
      String apiUrl = "https://wingx.shop/api/invoice-lotteries/menu";

      var response = await dio.get(apiUrl);

      // 使用Set来自动去除重复项，然后再转换为List
      var yearsSet =
          response.data.map((item) => item['year'] as String).toSet();
      var monthsSet =
          response.data.map((item) => item['month'] as String).toSet();

      setState(() {
        years = List<String>.from(yearsSet);
        months = List<String>.from(monthsSet);
      });
    } catch (error) {
      print("Failed to load years and months: $error");
    }
  }

  _fetchData() async {
    String apiUrl =
        "https://wingx.shop/api/invoice-lotteries?year=$selectedYear&month=$selectedMonth";

    try {
      var response = await dio.get(apiUrl);

      setState(() {
        apiData = response.data;
      });
    } catch (error) {
      print("Failed to load data: $error");
    }
  }

  Future<String?> _scanQR() async {
    try {
      var qrText = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 250, // 定義寬度
                    height: 250, // 定義高度
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Background color
                      shape: const CircleBorder(), // Shape
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Close the QR scanner
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      );
      return qrText != null && qrText.length >= 10
          ? qrText.substring(0, 10)
          : qrText;
    } catch (ex) {
      print("Scanning Error: $ex");
      return null;
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen((scanData) {
      controller.dispose(); // Stop scanning after first scan
      Navigator.pop(context, scanData.code);
    });
  }

  String _matchQRData(String data) {
    String lastThreeDigits = data.substring(data.length - 3);
    String lastEightDigits = data.substring(data.length - 8);

    for (var item in apiData) {
      var specialBonusNumbers = item['special_bonus'].split('、');
      var specialAwardNumbers = item['special_award'].split('、');
      var jackpotNumbers = item['jackpot'].split('、');

      for (var number in specialBonusNumbers) {
        if (number.endsWith(lastEightDigits)) {
          return '特別奬中奬';
        }
      }

      for (var number in specialAwardNumbers) {
        if (number.endsWith(lastThreeDigits)) {
          return '特奬中奬';
        }
      }

      for (var number in jackpotNumbers) {
        if (number.endsWith(lastThreeDigits)) {
          return '頭奬中奬';
        }
      }
    }

    return '沒有中奬';
  }
}
