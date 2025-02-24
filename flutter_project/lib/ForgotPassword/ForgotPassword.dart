import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                const lineUrl = "https://line.me/ti/p/mp-WHTJnIq";
                try {
                  final Uri url = Uri.parse(lineUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ไม่สามารถเปิดลิงก์ได้")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                  );
                }
              },
              child: const CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage('assets/PNG/line.jpg'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ติดต่อแอดมินกรุณาแตะที่รูปภาพ LINE',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}