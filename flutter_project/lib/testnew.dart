import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/ProductProvider/ProductProvider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_project/AddProductPage/AddProduct.dart';
import 'package:flutter_project/HistoryPage/historyPage.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:flutter_project/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project/Product/product.dart'
    show Product, ProductDetailPage, ProductListPage;

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, required this.role});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<Product>> productsFuture;
  String? role;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProductsFromApi();
  }

  Future<List<Product>> fetchProductsFromApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleNew = prefs.getString('role');
    setState(() {
      role = roleNew;
    });

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

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('ผลการสแกน'),
              content: Text('ข้อมูลบาร์โค้ด: ${result.rawContent}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการสแกน: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int availableStock = 100;
    int damagedStock = 5;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('ระบบจัดการสินค้า'),
            Image.asset('assets/PNG/LOGO.png', height: 40, width: 40),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              SharedPreferences.getInstance().then((prefs) {
                prefs.remove('token');
                prefs.remove('role');
              });
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Login()));
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 245, 245, 241),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildSquareBoxWithText(
                  context,
                  'สวัสดีคุณ Besttoo',
                  'สินค้าคงเหลือ: $availableStock ชิ้น\nสินค้าเสียหาย: $damagedStock ชิ้น',
                  AddProductPage(),
                ),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                FutureBuilder<List<Product>>(
                  future: productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('ไม่มีสินค้าล่าสุด'));
                    } else {
                      final products = snapshot.data!;
                      return _buildProductGrid(products);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanBarcode,
        child: const Icon(Icons.center_focus_weak),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หมวดหมู่',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(155, 252, 252, 252),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/box.png',
                      'สินค้า',
                      ProductListPage(),
                    ),
                  if (role == '2' || role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/new-product.png',
                      'เพิ่มเข้าใหม่',
                      AddProductPage(),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (role == '3' || role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/out-of-stock.png',
                      'จองสินค้า',
                      ProductProvider(),
                    ),
                  if (role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/file.png',
                      'คืนสินค้า',
                      HistoryPage(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final uniqueProducts = products.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
      ),
      itemCount: uniqueProducts.length,
      itemBuilder: (context, index) {
        final product = uniqueProducts[index];
        return _buildSquareImageWithDescription(
          context,
          product.imageUrl,
          product.name,
          product,
        );
      },
    );
  }
}

Widget _buildSquareBoxWithText(
    BuildContext context, String text, String description, Widget nextPage,
    {double width = 100, double height = 150}) {
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
        borderRadius: BorderRadius.circular(30.0),
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
                color: Color.fromARGB(43, 0, 0, 0),
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

Widget _buildSquareImageWithDescription(
    BuildContext context, String imagePath, String description, Product product,
    {double width = 150, double height = 130, bool withBorder = false}) {
  return GestureDetector(
    onTap: () {
      // เมื่อคลิกที่สินค้าจะไปยังหน้ารายละเอียดสินค้า
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: product),
        ),
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
