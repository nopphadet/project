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
            colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                const lineUrl = "https://line.me/R/ti/p/your_admin_line_id";
                if (await canLaunchUrl(Uri.parse(lineUrl))) {
                  await launchUrl(Uri.parse(lineUrl),
                      mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ไม่สามารถเปิดลิงก์ได้")),
                  );
                }
              },
              child: const CircleAvatar(
                radius: 80,
                backgroundImage:
                    AssetImage('assets/PNG/line.jpg'), // ใส่รูปภาพของคุณที่นี่
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ติดต่อแอดมินกรุณาแตะที่รูปภาพ LINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
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
