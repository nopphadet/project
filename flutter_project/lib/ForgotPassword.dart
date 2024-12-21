import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  // ฟังก์ชันตรวจสอบรูปแบบอีเมล
  bool isValidEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  // ฟังก์ชันส่งคำขอรีเซ็ตรหัสผ่าน
  Future<void> sendResetEmail() async {
    final email = emailController.text;

    // ตรวจสอบรูปแบบอีเมล
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกอีเมลที่ถูกต้อง')),
      );
      return;
    }

    setState(() {
      isLoading = true; // ตั้งค่าสถานะการโหลดเป็น true
    });

    final url = Uri.parse(
        'https://hfm99nd8-7070.asse.devtunnels.ms/password'); // URL ของ API
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() {
        isLoading = false; // ตั้งค่าสถานะการโหลดเป็น false เมื่อเสร็จ
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );

        // จัดเก็บ Token ใน SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('auth_token', data['token']); // เก็บ Token

        // ถ้าต้องการให้ผู้ใช้ไปยังหน้าล็อกอินหรือหน้าหลัก
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'])),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // ตั้งค่าสถานะการโหลดเป็น false เมื่อเกิดข้อผิดพลาด
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลืมรหัสผ่าน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'กรุณากรอกอีเมลของคุณ',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator() // แสดงการโหลดเมื่อกำลังส่งคำขอ
                : ElevatedButton(
                    onPressed: sendResetEmail,
                    child: const Text('ส่งรหัสผ่านชั่วคราว'),
                  ),
          ],
        ),
      ),
    );
  }
}
