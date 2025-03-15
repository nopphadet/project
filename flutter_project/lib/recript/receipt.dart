import 'package:flutter/material.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Reservation {
  final int reserveId;
  final String userId;
  final int productId;
  final int quantity;
  final int actualQuantity;
  final int returnedQuantity;
  final String status;
  final String productName;
  final String imageUrl;
  final String Createdat;

  Reservation({
    required this.reserveId,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.actualQuantity,
    required this.returnedQuantity,
    required this.status,
    required this.productName,
    required this.imageUrl,
    required this.Createdat,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reserveId: json['reserve_id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      actualQuantity: json['actual_quantity'] ?? 0,
      returnedQuantity: json['returned_quantity'] ?? 0,
      status: json['status'] ?? '',
      productName: json['product_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      Createdat: json['created_at'] ?? '',
    );
  }
}

class Recipt extends StatefulWidget {
  @override
  _ReciptState createState() => _ReciptState();
}

class _ReciptState extends State<Recipt> with TickerProviderStateMixin {
  String? role;
  String? currentUserId;
  late Future<List<Reservation>> _reservationsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _reservationsFuture = fetchReservationsFromApi();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role');
      currentUserId = prefs.getString('userID') ?? '';
    });
  }

  Future<List<Reservation>> fetchReservationsFromApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleNew = prefs.getString('role');

    const String apiUrl =
        "https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider/reservations";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception("ข้อมูลจาก API ว่างเปล่า");
        }

        final dynamic jsonData = json.decode(response.body);
        List<dynamic> data;
        if (jsonData is Map<String, dynamic> && jsonData['data'] != null) {
          data = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List<dynamic>) {
          data = jsonData;
        } else {
          throw Exception("โครงสร้างข้อมูลจาก API ไม่ถูกต้อง");
        }

        if (data.isEmpty) {
          throw Exception("ไม่มีข้อมูลการจองใน API");
        }

        List<Reservation> reservations =
            data.map((item) => Reservation.fromJson(item)).toList();
        if (currentUserId != null && currentUserId!.isNotEmpty) {
          reservations = reservations
              .where((reservation) => reservation.userId == currentUserId)
              .toList();
        }

        setState(() {
          role = roleNew;
        });
        return reservations;
      } else {
        throw Exception(
            "ไม่สามารถดึงข้อมูลการจองได้: Status Code ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการวัสดุ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 5)],
          ),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Reservation>>(
          future: _reservationsFuture,
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
            } else if (snapshot.hasData) {
              final reservations = snapshot.data!;
              if (reservations.isEmpty) {
                return const Center(
                  child: Text(
                    'ไม่มีสินค้าในระบบสำหรับคุณ',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    return _buildReservationCard(context, reservations[index], index);
                  },
                ),
              );
            } else {
              return const Center(
                child: Text(
                  'ไม่มีข้อมูลสินค้า',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation reservation, int index) {
    final Map<String, String> statusMap = {
      'pending': 'รอดำเนินการ',
      'confirmed': 'อนุมัติ',
      'returned': 'คืนสำเร็จ',
      'cancelled': 'ไม่อนุมัติ',
    };
    final thaiStatus = statusMap[reservation.status.toLowerCase()] ?? reservation.status;

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
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      reservation.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                  title: Text(
                    '${reservation.productName} (การจอง #${reservation.reserveId})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('จำนวนที่จอง: ${reservation.quantity} ชิ้น'),
                      Text('จำนวนจริงที่ได้: ${reservation.actualQuantity} ชิ้น'),
                      Text('จำนวนที่คืน: ${reservation.returnedQuantity} ชิ้น'),
                      Text('สถานะ: $thaiStatus'),
                      Text('วันที่จอง: ${reservation.Createdat}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProductDetailPageOne extends StatefulWidget {
  final Product product;
  const ProductDetailPageOne({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPageOne>
    with TickerProviderStateMixin {
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';
  final String deleteURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/products/delete';
  final TextEditingController _quantityController = TextEditingController();
  late Future<List<Reservation>> _reservationsFuture;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = fetchReservationsForProduct(widget.product.id);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<List<Reservation>> fetchReservationsForProduct(int productId) async {
    const String apiUrl =
        "https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider/reservations";
    try {
      final response =
          await http.get(Uri.parse('$apiUrl?product_id=$productId'));
      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        List<dynamic> data;
        if (jsonData is Map<String, dynamic> && jsonData['data'] != null) {
          data = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List<dynamic>) {
          data = jsonData;
        } else {
          throw Exception("โครงสร้างข้อมูลจาก API ไม่ถูกต้อง");
        }
        return data.map((item) => Reservation.fromJson(item)).toList();
      } else {
        throw Exception("ไม่สามารถดึงข้อมูลการจองได้: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> _deleteProduct(int productId) async {
    if (productId == 0 || productId == null) {
      _showSnackBar('ไม่พบ ID สินค้าที่ถูกต้อง');
      return;
    }

    final url = Uri.parse(deleteURL);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': productId}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('ลบสินค้าสำเร็จ');
        Navigator.pop(context);
      } else {
        _showSnackBar('ไม่สามารถลบสินค้าได้: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _reserveProduct(int productId, int quantity) async {
    if (quantity <= 0) {
      _showSnackBar('กรุณากรอกจำนวนที่ถูกต้อง');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userID") ?? '0';
    final url = Uri.parse('$baseURL/reserve');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        _showReservationConfirmation(context, widget.product.name, quantity);
        setState(() {
          _reservationsFuture = fetchReservationsForProduct(productId);
        });
      } else {
        _showSnackBar('ไม่สามารถจองสินค้าได้');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showReservationConfirmation(
      BuildContext context, String productName, int quantity) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'การจองสำเร็จ',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'คุณได้ทำการจอง "$productName" จำนวน $quantity ชิ้นเรียบร้อยแล้ว!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 5)],
          ),
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
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              _deleteProduct(widget.product.id);
            },
            tooltip: 'ลบสินค้า',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 280,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 280,
                          height: 280,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ชื่อสินค้า: ${widget.product.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'สินค้าคงเหลือ: ${widget.product.stock} ชิ้น',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'รายการการจอง:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(
                height: 200, // กำหนดความสูงให้ ListView
                child: FutureBuilder<List<Reservation>>(
                  future: _reservationsFuture,
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
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final reservations = snapshot.data!;
                      if (reservations.isEmpty) {
                        return const Center(child: Text('ไม่มีข้อมูลการจอง'));
                      }
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.builder(
                          itemCount: reservations.length,
                          itemBuilder: (context, index) {
                            final reservation = reservations[index];
                            final Map<String, String> statusMap = {
                              'pending': 'รอดำเนินการ',
                              'confirmed': 'อนุมัติ',
                              'returned': 'คืนสำเร็จ',
                              'cancelled': 'ไม่อนุมัติ',
                            };
                            final thaiStatus =
                                statusMap[reservation.status.toLowerCase()] ??
                                    reservation.status;
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
                                    child: Card(
                                      elevation: 5,
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.white, Colors.white],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.3),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              reservation.imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                );
                                              },
                                            ),
                                          ),
                                          title: Text(
                                            '${reservation.productName} (การจอง #${reservation.reserveId})',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('จำนวนที่จอง: ${reservation.quantity} ชิ้น'),
                                              Text('จำนวนจริงที่ได้: ${reservation.actualQuantity} ชิ้น'),
                                              Text('จำนวนที่คืน: ${reservation.returnedQuantity} ชิ้น'),
                                              Text('สถานะ: $thaiStatus'),
                                              Text('User ID: ${reservation.userId}'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      return const Center(child: Text('ไม่มีข้อมูล'));
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'จำนวนที่ต้องการจอง',
                  labelStyle: const TextStyle(color: Colors.red),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: AnimatedScaleButton(
                  onPressed: () => _reserveProduct(widget.product.id,
                      int.tryParse(_quantityController.text) ?? 0),
                  child: const Text(
                    'จองวัสดุ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AnimatedScaleButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}