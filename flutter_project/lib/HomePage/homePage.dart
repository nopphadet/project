import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/foundation.dart';
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
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<Product>> productsFuture;
  String? role;
  // ignore: unused_field
  bool _isLoading = false;
  String? username;
  int? quantity;

 final TextEditingController _searchController = TextEditingController();
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';

  List<Map<String, dynamic>> _products = [];


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // void _showSnackBar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message)),
  //   );
  // }

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProductsFromApi();
    fetchUserName();
    fetchProductsFromApi();
  }

  Future<void> _fetchProductData(String searchText) async {
    if (searchText.isEmpty) {
      _showSnackBar('กรุณาป้อนชื่อวัสดุที่ต้องการค้นหา');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$baseURL/search?name=$searchText');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(data);
          });
        } else {
          _showSnackBar('ไม่พบข้อมูลสินค้า');
          setState(() => _products.clear());
        }
      } else {
        _showSnackBar('ข้อผิดพลาดจากเซิร์ฟเวอร์: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reserveProduct(int productId, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userID"); // Replace with actual user ID
    final url = Uri.parse('$baseURL/reserve');

    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'user_id': userId,
            'product_id': productId,
            'quantity': quantity,
          }));

      if (response.statusCode == 200) {
        _showSnackBar('การจองสินค้าสำเร็จ');
      } else {
        _showSnackBar('เกิดข้อผิดพลาดในการจอง');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _confirmReservation(int reservationId) async {
    final url = Uri.parse('$baseURL/confirm');

    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'reservation_id': reservationId,
          }));

      if (response.statusCode == 200) {
        _showSnackBar('ยืนยันการจองสำเร็จ');
      } else {
        _showSnackBar('เกิดข้อผิดพลาดในการยืนยันการจอง');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showQuantityDialog(int productId) {
    TextEditingController _quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เลือกจำนวนสินค้า'),
        content: TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'ใส่จำนวน'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              int quantity = int.tryParse(_quantityController.text) ?? 0;
              if (quantity > 0) {
                _reserveProduct(productId, quantity);
              } else {
                _showSnackBar('กรุณากรอกจำนวนที่ถูกต้อง');
              }
            },
            child: Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usernameNew = prefs.getString('username');
    setState(() {
      username = usernameNew;
    });
  }

  Future<List<Product>> fetchProductsFromApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleNew = prefs.getString('role');

    const String apiUrl =
        "https://hfm99nd8-7070.asse.devtunnels.ms/showproducts";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("=====================================");
        print(data);
        print("=====================================");
        //loop เก็บค่าData มาบวกกัน{stock}
        List<Product> products =
            data.map((item) => Product.fromJson(item)).toList();
        quantity = products.map((e) => e.stock).reduce((a, b) => a + b);
        setState(() {
          role = roleNew;
          quantity = quantity;
        });
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
      // เรียกสแกนบาร์โค้ด
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        // แสดงข้อความแจ้งระหว่างรอการตอบกลับจากเซิร์ฟเวอร์
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        final response = await http.post(
          Uri.parse("https://hfm99nd8-7070.asse.devtunnels.ms/api/scan"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"barcode": result.rawContent}),
        );

        Navigator.of(context).pop(); // ปิด Dialog เมื่อได้รับผลลัพธ์แล้ว

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data["status"] == "not_found") {
            // ถ้าไม่มีสินค้า ให้ไปหน้า AddProductPage ทันที
           Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AddProductPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
          } else {
            String message = data["message"];
            String? newQuantity = data["new_quantity"]?.toString();

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('ผลการสแกนสำเร็จ'),
                  content: Text('$message\nจำนวนคงเหลือใหม่: $newQuantity'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // เรียกการสแกนใหม่อีกครั้ง
                        scanBarcode();
                      },
                      child: const Text('ตกลง'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('ข้อผิดพลาด'),
                content: Text('การสแกนล้มเหลว: ${response.body}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // เรียกการสแกนใหม่อีกครั้ง
                      scanBarcode();
                    },
                    child: const Text('ตกลง'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการสแกน: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ข้อผิดพลาด'),
            content: Text('เกิดข้อผิดพลาดในการสแกน: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // เรียกการสแกนใหม่อีกครั้ง
                  scanBarcode();
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    }
  }
 

  @override
  Widget build(BuildContext context) {
    // int availableStock = 100;
    int damagedStock = 5;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/PNG/LOGO.png', height: 40, width: 40),
            Text(
              'Stock MIS',
              // style: TextStyle(color: Colors.white),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            ),
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
        decoration: BoxDecoration(
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
                const SizedBox(height: 90),
                Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 255, 255),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดีคุณ $username',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 34, 31, 31),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'สินค้าคงเหลือ: $quantity ชิ้น\nสินค้าเสียหาย: $damagedStock ชิ้น',
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
        child: const Icon(Icons.center_focus_weak, color: Colors.white),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
      ),
    );
  }
Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'ค้นหาวัสดุ',
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(Icons.search),
          onPressed: () => _fetchProductData(_searchController.text.trim()),
        ),
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
        const SizedBox(height: 10),
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
                  if (role == '2' || role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/box.png',
                      'วัสดุสำนักงาน',
                      ProductListPage(),
                    ),
                  if (role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/new-product.png',
                      'เพิ่มวัสดุใหม่',
                      AddProductPage(),
                    ),
                  if (role == '2' || role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/out-of-stock.png',
                      'จองวัสดุ',
                      ProductProvider(),
                    ),
                  if (role == '2' || role == '1')
                    _buildCategoryButton(
                      context,
                      'assets/PNG/file.png',
                      'รายการจอง-คืน',
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
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>('_searchController', _searchController));
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ProductDetailPage(product: product),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
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
