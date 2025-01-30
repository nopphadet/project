import 'package:flutter/material.dart';
import 'package:flutter_project/ForgotPassword/ForgotPassword.dart';
import 'package:flutter_project/HomePage/homePage.dart';
// import 'package:flutter_project/register/register.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage(); // Secure storage for token

// ฟังก์ชันสำหรับล็อกอิน
  Future<void> login(BuildContext context) async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final url = Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'role', value: data['role']);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', data['token']);
        prefs.setString('role', data['role']);

        print("=====================================");
        print(prefs.getString('token'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginPage(
                    role: '',
                  )),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'ไม่สามารถเข้าสู่ระบบได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    }
  }

  checkLogin(context) {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getString('token') != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginPage(
                    role: '',
                  )),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    checkLogin(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 0, 0),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/PNG/LOGO.png',
                    height: 220,
                    width: 220,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ยินดีต้อนรับ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'เข้าสู่ระบบบัญชีของคุณ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(179, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const Text(
                    "คุณลืมบัญชีใช่ไหม",
                    style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ContactAdmin()),
                      );
                    },
                    child: const Text(
                      'ลืมรหัสผ่าน',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 209, 42, 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     const Text(
                  //       "ยังไม่มีบัญชีใช่ไหม",
                  //       style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                  //     ),
                  //     TextButton(
                  //       onPressed: () {
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(builder: (context) => Register()),
                  //         );
                  //       },
                  //       child: const Text(
                  //         'ลงทะเบียน',
                  //         style: TextStyle(
                  //           color: Color.fromARGB(255, 0, 0, 0),
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
