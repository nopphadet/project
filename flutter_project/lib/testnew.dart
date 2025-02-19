import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.brown[300], // สีพื้นหลังคล้ายภาพตัวอย่าง
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 5),
              Text(
                "New York, USA",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Icon(Icons.notifications, color: Colors.white),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.brown[800]),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Search",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_cart, color: Colors.brown[800]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
