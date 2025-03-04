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
import 'package:flutter_project/Product/product.dart'
    show Product, ProductDetailPage, ProductListPage;
import 'package:flutter_project/recript/receipt.dart';
import 'package:flutter/animation.dart'; // สำหรับ Animation

class HomePage1 extends StatefulWidget {
  final String role;

  const HomePage1({super.key, required this.role});

  @override
  _HomePage1State createState() =>
      _HomePage1State(); // เปลี่ยนเป็น _HomePage1State
}

void _showMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 200,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.support_agent),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ContactAdmin()));
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.remove('token');
                  prefs.remove('role');
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
                // Perform logout operation
              },
            ),
          ],
        ),
      );
    },
  );
}

class _HomePage1State extends State<HomePage1>
    with SingleTickerProviderStateMixin {
  late Future<List<Product>> productsFuture;
  String? role;
  // ignore: unused_field
  bool _isLoading = false;
  String? username;
  int? quantity;
  late AnimationController _controller; // Controller สำหรับ Animation
  // ignore: unused_field
  late Animation<double> _animation; // Animation สำหรับ Scale

  @override
  void initState() {
    super.initState();
    print("initState");
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    productsFuture = fetchProductsFromApi();
    fetchUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage1 oldWidget) {
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
          builder: (context) => Center(
              child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 167, 0, 0))),
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
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black12,
                title: Text('วัสดุไม่พบในระบบ',
                    style: TextStyle(color: Colors.red[700])),
                content: Text('คุณต้องการสร้างวัสดุใหม่หรือไม่?',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ยกเลิก',
                        style: TextStyle(color: Colors.grey[400])),
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
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                      begin: Offset(1.0, 0.0), end: Offset.zero)
                                  .animate(animation),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Text('สร้างใหม่',
                        style: TextStyle(color: Colors.green[700])),
                  ),
                ],
              ),
            );
          } else {
            String message = data["message"];
            String? newQuantity = data["new_quantity"]?.toString();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black12,
                title: Text('ผลการสแกนสำเร็จ',
                    style: TextStyle(color: Colors.green[700])),
                content: Text('$message\nจำนวนคงเหลือใหม่: $newQuantity',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      scanBarcode();
                    },
                    child: Text('ตกลง',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 167, 0, 0))),
                  ),
                ],
              ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black12,
              title:
                  Text('ข้อผิดพลาด', style: TextStyle(color: Colors.red[700])),
              content: Text('การสแกนล้มเหลว: ${response.body}',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    scanBarcode();
                  },
                  child: Text('ตกลง',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 167, 0, 0))),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการสแกน: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black12,
          title: Text('ข้อผิดพลาด', style: TextStyle(color: Colors.red[700])),
          content: Text('เกิดข้อผิดพลาดในการสแกน: $e',
              style: TextStyle(fontSize: 16, color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                scanBarcode();
              },
              child: Text('ตกลง',
                  style:
                      TextStyle(color: const Color.fromARGB(255, 167, 0, 0))),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      productsFuture = fetchProductsFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 143, 0, 0),
                const Color.fromARGB(255, 161, 13, 136)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset('assets/PNG/LOGO.png', height: 40, width: 40),
            ),
            const SizedBox(width: 10),
            Text(
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
                      blurRadius: 4)
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 30),
              onPressed: () => _showMenu(context),
              splashRadius: 25,
              splashColor: Colors.white24,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255)
            ],
            center: Alignment.topCenter,
            radius: 1.5,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color.fromARGB(255, 167, 0, 0),
          backgroundColor: Colors.white,
          displacement: 50,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildUserInfoCard(),
                    SizedBox(height: 30),
                    _buildCategorySection(),
                    SizedBox(height: 30),
                    _buildLatestProductsSection(),
                    SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanBarcode,
        child: Icon(Icons.center_focus_weak, color: Colors.white, size: 50),
        backgroundColor: const Color.fromARGB(255, 167, 0, 0),
        elevation: 10,
        shape: StadiumBorder(),
        splashColor: Colors.white24,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 242, 178, 178), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 234, 128, 128).withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromARGB(255, 167, 0, 0),
              child: Icon(Icons.person, color: Colors.white, size: 35),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username ?? "ไม่ระบุ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'ThaiSans',
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'วันที่: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'วัสดุคงเหลือ: ${quantity ?? 0} ชิ้น',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                color: Colors.red[200] ?? Colors.red,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red[100]!.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (role == '2' || role == '1')
                _buildCategoryButton(context, 'assets/PNG/box.png',
                    'วัสดุสำนักงาน', ProductListPage()),
              if (role == '1')
                _buildCategoryButton(context, 'assets/PNG/new-product.png',
                    'เพิ่มวัสดุใหม่', AddProductPage()),
              if (role == '2' || role == '1')
                _buildCategoryButton(context, 'assets/PNG/out-of-stock.png',
                    'จองวัสดุ', ProductProvider()),
              if (role == '2' || role == '1')
                _buildCategoryButton(
                    context, 'assets/PNG/file.png', 'รายการจอง-คืน', Recipt()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLatestProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'วัสดุล่าสุด',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'ThaiSans',
            shadows: [
              Shadow(
                  color: const Color.fromARGB(255, 234, 128, 128) ??
                      const Color.fromARGB(255, 212, 0, 0),
                  offset: Offset(2, 2),
                  blurRadius: 4)
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      color: const Color.fromARGB(255, 167, 0, 0)));
            } else if (snapshot.hasError) {
              return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16)),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('ไม่มีวัสดุล่าสุด',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16)),
              );
            } else {
              final products = snapshot.data!;
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween<Offset>(
                                  begin: Offset(0.5, 0), end: Offset.zero)
                              .animate(animation),
                          child: child));
                },
                child: _buildProductGrid(products),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final uniqueProducts = products.take(4).toList();
    return Container(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 30,
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
      ),
    );
  }
}

Widget _buildSquareImageWithDescription(BuildContext context, String imagePath,
    String description, Product product) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Hero(
            tag: 'product-${product.id}',
            child: ProductDetailPage(product: product),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CustomTransition(
              animation: animation,
              child: child,
            );
          },
        ),
      );
    },
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 160,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 242, 178, 178), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 234, 128, 128).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                width: 120,
                height: 120,
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Container(
              width: 160,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontFamily: 'ThaiSans',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            return SlideTransition(
              position: Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero)
                  .animate(animation),
              child: child,
            );
          },
        ),
      );
    },
    child: Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 242, 178, 178),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 234, 128, 128).withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imagePath,
                width: 40, height: 40, fit: BoxFit.cover),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontFamily: 'ThaiSans',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class CustomTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const CustomTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          transform:
              Matrix4.translationValues(0.0, 50 * (1.0 - animation.value), 0.0)
                ..scale(1.0 + 0.1 * (1.0 - animation.value)),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage1(role: "1"), // ตัวอย่าง role
    theme: ThemeData(
      fontFamily: 'ThaiSans',
    ),
  ));
}
