import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
      home: MyHomePage(),
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
                  child: Text(year),
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
                  child: Text(month),
                  value: month,
                );
              }).toList(),
              hint: const Text("月份"),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text("查 詢"),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: apiData.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = apiData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(text: "特別奬:\n"),
                              ...item['special_bonus']
                                  .split('、')
                                  .expand((number) {
                                return [
                                  TextSpan(
                                      text: number.substring(
                                          0, number.length - 3),
                                      children: [
                                        TextSpan(
                                            text: number
                                                .substring(number.length - 3),
                                            style: const TextStyle(
                                                color: Colors.red))
                                      ]),
                                  const TextSpan(text: '\n')
                                ];
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(text: "特奬:\n"),
                              ...item['special_award']
                                  .split('、')
                                  .expand((number) {
                                return [
                                  TextSpan(
                                      text: number.substring(
                                          0, number.length - 3),
                                      children: [
                                        TextSpan(
                                            text: number
                                                .substring(number.length - 3),
                                            style: const TextStyle(
                                                color: Colors.red))
                                      ]),
                                  const TextSpan(text: '\n')
                                ];
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(text: "頭奬:\n"),
                              ...item['jackpot'].split('、').expand((number) {
                                return [
                                  TextSpan(
                                      text: number.substring(
                                          0, number.length - 3),
                                      children: [
                                        TextSpan(
                                            text: number
                                                .substring(number.length - 3),
                                            style: const TextStyle(
                                                color: Colors.red))
                                      ]),
                                  const TextSpan(text: '\n')
                                ];
                              }).toList(),
                            ],
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                },
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
              child: const Text("掃描二維碼"),
            ),
            Text('掃描結果: $qrData'),
            Text(
              '比對結果: $matchResult',
              style: TextStyle(
                color: matchResult == '中奬' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
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
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
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
      return qrText;
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
    for (var item in apiData) {
      if (item['special_bonus'].endsWith(lastThreeDigits) ||
          item['special_award'].endsWith(lastThreeDigits) ||
          item['jackpot'].endsWith(lastThreeDigits)) {
        return '中奬';
      }
    }
    return '沒有中奬';
  }
}
