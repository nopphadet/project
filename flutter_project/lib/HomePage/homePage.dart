import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_project/AddProductPage/AddProduct.dart';
import 'package:flutter_project/HistoryPage/historyPage.dart';
import 'package:flutter_project/Outfoproduct/outfoproduct.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:flutter_project/login/login.dart';

// โมเดลสินค้า
class Product {
  final String productName;
  final String imageUrl;
  final int quantity;

  Product({
    required this.productName,
    required this.imageUrl,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['product_name'],
      imageUrl: json['image_url'],
      quantity: json['quantity'],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProductsFromApi();
  }

  // ดึงข้อมูลสินค้าจาก API
  Future<List<Product>> fetchProductsFromApi() async {
    const String apiUrl =
        "https://hfm99nd8-7070.asse.devtunnels.ms/showproducts";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception("ไม่สามารถดึงข้อมูลสินค้าได้");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int availableStock = 100; // ตัวอย่างข้อมูล
    int damagedStock = 5; // ตัวอย่างข้อมูล
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบจัดการสินค้า'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 229, 9, 20), // Red color on top
              Color.fromARGB(255, 245, 245, 241), // White color on bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 50),
              _buildSquareBoxWithText(
                context,
                'สวัสดีคุณ Besttoo',
                'สินค้าคงเหลือ: $availableStock ชิ้น\nสินค้าเสียหาย: $damagedStock ชิ้น',
                AddProductPage(),
                width: screenWidth * 0.9,
                height: screenHeight * 0.25,
              ),
              const SizedBox(height: 20),
              const Text(
                'หมวดหมู่',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildCategoryButton(context, 'assets/PNG/box.png',
                        'สินค้า', ProductListPage()),
                    const SizedBox(width: 15),
                    _buildCategoryButton(context, 'assets/PNG/new-product.png',
                        'เพิ่มเข้า', AddProductPage()),
                    const SizedBox(width: 15),
                    _buildCategoryButton(context, 'assets/PNG/out-of-stock.png',
                        'นำออก', ManageProductPage()),
                    const SizedBox(width: 15),
                    _buildCategoryButton(context, 'assets/PNG/file.png',
                        'ประวัติ', HistoryPage()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'รายการล่าสุด',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 34, 31, 31),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Product>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('ไม่มีสินค้าล่าสุด'),
                    );
                  } else {
                    final products = snapshot.data!
                        .take(4) // ดึงรายการแค่ 4 รายการ
                        .toList();

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // กำหนดให้มี 2 คอลัมน์ในแถว
                        crossAxisSpacing: 20, // กำหนดระยะห่างระหว่างคอลัมน์
                        mainAxisSpacing: 20, // กำหนดระยะห่างระหว่างแถว
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildSquareImageWithDescription(
                          context,
                          product.imageUrl,
                          product.productName,
                          AddProductPage(),
                          width: screenWidth * 0.3,
                          height: screenHeight * 0.15,
                          withBorder: true,
                        );
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareBoxWithText(
      BuildContext context, String text, String description, Widget nextPage,
      {double width = 350, double height = 200}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 245, 245, 241),
              Color.fromARGB(255, 245, 245, 241),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 34, 31, 31),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 34, 31, 31),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context, String imagePath, String label, Widget nextPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSquareImageWithDescription(BuildContext context,
      String imagePath, String description, Widget nextPage,
      {double width = 120, double height = 120, bool withBorder = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: withBorder
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: SizedBox(
                width: width,
                height: height,
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              )),
        ],
      ),
    );
  }
}
