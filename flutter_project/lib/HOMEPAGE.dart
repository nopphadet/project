import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/ForgotPassword/ForgotPassword.dart';
import 'package:flutter_project/ProductProvider/ProductProvider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_project/AddProductPage/AddProduct.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:flutter_project/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../recript/receipt.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, required this.role});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late Future<List<Product>> productsFuture;
  String? role;
  String? username;
  int? quantity;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print("initState");
    productsFuture = fetchProductsFromApi();
    fetchUserName();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LoginPage oldWidget) {
    print("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
    setState(() {
      productsFuture = fetchProductsFromApi();
    });
  }

  @override
  void didChangeDependencies() {
    print("didChangeDependencies");
    super.didChangeDependencies();
    productsFuture = fetchProductsFromApi();
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
        List<Product> products =
            data.map((item) => Product.fromJson(item)).toList();
        quantity = products.isNotEmpty
            ? products.map((e) => e.stock).reduce((a, b) => a + b)
            : 0;
        setState(() {
          role = roleNew;
          quantity = quantity;
        });
        return products;
      } else {
        throw Exception("ไม่สามารถดึงข้อมูลวัสดุได้: ${response.statusCode}");
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
          barrierDismissible: false,
          builder: (context) => ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.elasticOut,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  strokeWidth: 5,
                ),
              ),
            ),
          ),
        );

        final response = await http.post(
          Uri.parse("https://hfm99nd8-7070.asse.devtunnels.ms/api/scan"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"barcode": result.rawContent}),
        );

        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data["status"] == "not_found") {
            showDialog(
              context: context,
              builder: (context) => ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text(
                    'วัสดุไม่พบในระบบ',
                    style: TextStyle(color: Colors.red),
                  ),
                  content: const Text('คุณต้องการสร้างวัสดุใหม่หรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    AddProductPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('สร้างใหม่'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            String message = data["message"];
            String? newQuantity = data["new_quantity"]?.toString();

            showDialog(
              context: context,
              builder: (context) => ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text(
                    'ผลการสแกนสำเร็จ',
                    style: TextStyle(color: Colors.green),
                  ),
                  content: Text('$message\nจำนวนคงเหลือใหม่: $newQuantity'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        scanBarcode();
                      },
                      child: const Text('ตกลง'),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  'ข้อผิดพลาด',
                  style: TextStyle(color: Colors.red),
                ),
                content: Text('การสแกนล้มเหลว: ${response.body}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      scanBarcode();
                    },
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการสแกน: $e');
      showDialog(
        context: context,
        builder: (context) => ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.elasticOut,
            ),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'ข้อผิดพลาด',
              style: TextStyle(color: Colors.red),
            ),
            content: Text('เกิดข้อผิดพลาดในการสแกน: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  scanBarcode();
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      productsFuture = fetchProductsFromApi();
      _animationController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset('assets/PNG/LOGO.png', height: 40, width: 40),
            ),
            const SizedBox(width: 10),
            const Text(
              'Stock MIS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'ThaiSans',
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.remove('token');
                  prefs.remove('role');
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              } else if (value == 'contact_admin') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ติดต่อ Admin',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(),
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactAdmin()),
                );
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 10),
                    const Text('ออกจากระบบ'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'contact_admin',
                child: Row(
                  children: [
                    const Icon(Icons.support_agent,
                        color: Color.fromARGB(255, 247, 32, 32)),
                    const SizedBox(width: 10),
                    const Text('ติดต่อ Admin'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 245, 245, 241)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 500),
                      scale: 1.0,
                      child: Container(
                        width: double.infinity,
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
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(50, 255, 64, 64),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color.fromARGB(40, 255, 0, 0),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Color.fromARGB(30, 220, 0, 0),
                              blurRadius: 25,
                              spreadRadius: 0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_circle,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      size: 47),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$username',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 34, 31, 31),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'วันที่: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 34, 31, 31),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'วัสดุคงเหลือ: $quantity ชิ้น',
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
                    ),
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 10),
                    Text(
                      'วัสดุล่าสุด',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'ThaiSans',
                        shadows: [
                          Shadow(
                            color: Colors.red[100] ?? Colors.red,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Product>>(
                      future: productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                strokeWidth: 5,
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'เกิดข้อผิดพลาด: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 18),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'ไม่มีวัสดุล่าสุด',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          );
                        } else {
                          final products = snapshot.data!;
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildProductGrid(products),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: scanBarcode,
          child: const Icon(Icons.center_focus_weak, color: Colors.white),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'หมวดหมู่',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'ThaiSans',
            shadows: [
              Shadow(
                color: Colors.red[100] ?? Colors.red,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color.fromARGB(255, 245, 245, 241)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(82, 255, 0, 0),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
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
                      'เพิ่มวัสดุ',
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
                      'จอง-คืน',
                      Recipt(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: uniqueProducts.length,
        itemBuilder: (context, index) {
          final product = uniqueProducts[index];
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / 10),
                    1.0,
                    curve: Curves.easeInOut,
                  ),
                ),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: _buildSquareImageWithDescription(
                    context,
                    product.imageUrl,
                    product.name,
                    product,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildSquareBoxWithText(
  BuildContext context,
  String text,
  String description,
  Widget nextPage, {
  double width = 100,
  double height = 100,
}) {
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
  BuildContext context,
  String imagePath,
  String label,
  Widget nextPage,
) {
  // กำหนดไอคอนตาม label
  IconData getIconForLabel(String label) {
    switch (label) {
      case 'วัสดุสำนักงาน':
        return Icons.inventory_2;
      case 'เพิ่มวัสดุ':
        return Icons.add_box;
      case 'จองวัสดุ':
        return Icons.bookmark;
      case 'จอง-คืน':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }

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
        AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: 1.0,
          child: Container(
            width: 55,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(17, 0, 0, 0),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              color: Colors.white,
            ),
            child: Center(
              child: Icon(
                getIconForLabel(label),
                size: 40,
                color: Colors.redAccent,
              ),
            ),
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
  BuildContext context,
  String imagePath,
  String description,
  Product product, {
  double width = 130,
  double height = 100,
  bool withBorder = false,
}) {
  return GestureDetector(
    onTap: () {
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
        Text(
          description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}