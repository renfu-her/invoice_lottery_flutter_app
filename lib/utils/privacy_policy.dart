import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:invoice_lottery/main.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String policyContent = "";

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicyData();
  }

  _fetchPrivacyPolicyData() async {
    // 這裡替換為您的隱私權政策API
    String apiUrl = "https://wingx.shop/api/get_policy/1";
    try {
      var response = await dio.get(apiUrl);
      setState(() {
        policyContent = response.data['content']; // 這裡根據API返回的結構進行調整
      });
    } catch (error) {
      print("Failed to load privacy policy data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隱私權政策'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(data: policyContent), // 在加载内容时显示一个加载指示器
      ),
    );
  }
}
