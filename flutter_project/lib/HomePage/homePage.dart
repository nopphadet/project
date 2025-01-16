import 'package:flutter/material.dart';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_project/AddProductPage/AddProduct.dart';
import 'package:flutter_project/HistoryPage/historyPage.dart';
import 'package:flutter_project/Outfoproduct/outfoproduct.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:flutter_project/login/login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    allProducts = getProductsFromDatabase();
    filteredProducts = allProducts;
  }

  @override
  Widget build(BuildContext context) {
    int availableStock = 100;
    int damagedStock = 5;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('ระบบจัดการสินค้า'),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
              // Handle login button press
              print('Login button pressed');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 229, 9, 20), // Red color on top
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
                  boxShadow: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildSquareImageWithDescription(context,
                      'assets/PNG/new-product.png', '', AddProductPage(),
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.15,
                      withBorder: true),
                  const SizedBox(width: 20),
                  _buildSquareImageWithDescription(context,
                      'assets/PNG/new-product.png', '', AddProductPage(),
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.15,
                      withBorder: true),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildSquareImageWithDescription(context,
                      'assets/PNG/new-product.png', '', ProductListPage(),
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.15,
                      withBorder: true),
                  const SizedBox(width: 20),
                  _buildSquareImageWithDescription(context,
                      'assets/PNG/new-product.png', '', AddProductPage(),
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.15,
                      withBorder: true),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await BarcodeScanner.scan();
          if (result.type == ResultType.Barcode) {
            // Handle the scanned barcode result here
            print('Scanned barcode: ${result.rawContent}');
          }
        },
        child: const Icon(Icons.qr_code, color: Colors.white),
        backgroundColor: Color.fromARGB(255, 229, 9, 20),
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
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 245, 245, 241),
              Color.fromARGB(255, 245, 245, 241),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
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
              boxShadow: [
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
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
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

List<Product> getProductsFromDatabase() {
  return [
    Product(name: 'สินค้า A', stock: 50),
    Product(name: 'สินค้า B', stock: 20),
  ];
}

class Product {
  final String name;
  final int stock;

  Product({required this.name, required this.stock});
}
