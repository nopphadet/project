import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    ));

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ระบบจัดการวัสดุ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeCard(userName: "Besttoo"),
            SizedBox(height: 20),
            StockStatusCard(stock: 100, lost: 5),
          ],
        ),
      ),
    );
  }
}

class WelcomeCard extends StatelessWidget {
  final String userName;

  WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สวัสดีคุณ $userName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('สินค้าคงเหลือ: 100 ชิ้น', style: TextStyle(fontSize: 16)),
          Text('สินค้าเสียหาย: 5 ชิ้น', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
        ],
      ),
    );
  }
}

class StockStatusCard extends StatelessWidget {
  final int stock;
  final int lost;

  StockStatusCard({required this.stock, required this.lost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สถานะสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('สินค้าคงเหลือ', style: TextStyle(fontSize: 16)),
              Text('$stock ชิ้น', style: TextStyle(fontSize: 16, color: Colors.green)),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: stock / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('สินค้าเสียหาย', style: TextStyle(fontSize: 16)),
              Text('$lost ชิ้น', style: TextStyle(fontSize: 16, color: Colors.red)),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: lost / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
 