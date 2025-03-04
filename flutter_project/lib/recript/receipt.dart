import 'package:flutter/material.dart';
import 'package:flutter_project/Product/product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Reservation {
  final int reserveId;
  final String userId; // ใช้ String ตาม API
  final int productId;
  final int quantity; // จำนวนที่จอง
  final int actualQuantity; // จำนวนจริงที่ได้
  final int returnedQuantity; // จำนวนที่คืน
  final String status; // คงไว้เป็นภาษาอังกฤษใน Model
  final String productName; // ชื่อสินค้าจาก products
  final String imageUrl; // URL รูปภาพจาก products
  final String Createdat; // เวลาที่จอง

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
      userId: json['user_id']?.toString() ?? '', // แปลงเป็น String
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

class _ReciptState extends State<Recipt> {
  String? role;
  String? currentUserId; // ตัวแปรสำหรับ userId ปัจจุบัน
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // โหลด userId และ role
    _reservationsFuture = fetchReservationsFromApi();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role');
      currentUserId =
          prefs.getString('userID') ?? ''; // ดึง userId จาก SharedPreferences
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
        // กรองรายการตาม userId ปัจจุบัน
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
          title:
              const Text('รายการวัสดุ', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
      body: FutureBuilder<List<Reservation>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            final reservations = snapshot.data!;
            if (reservations.isEmpty) {
              return const Center(child: Text('ไม่มีสินค้าในระบบสำหรับคุณ'));
            }
            return ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return _buildReservationCard(context, reservation);
              },
            );
          } else {
            return const Center(child: Text('ไม่มีข้อมูลสินค้า'));
          }
        },
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation reservation) {
    // Map สำหรับแปลง status เป็นภาษาไทย
    final Map<String, String> statusMap = {
      'pending': 'รอดำเนินการ',
      'confirmed': 'ยืนยันแล้ว',
      'returned': 'คืนแล้ว',
    };

    // ใช้ statusMap เพื่อแปลง status เป็นภาษาไทย ถ้าไม่มีให้ใช้ค่าต้นฉบับ
    final thaiStatus =
        statusMap[reservation.status.toLowerCase()] ?? reservation.status;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.network(
          reservation.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image_not_supported,
                size: 50, color: Colors.grey);
          },
        ),
        title: Text(
            '${reservation.productName} (การจอง #${reservation.reserveId})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จำนวนที่จอง: ${reservation.quantity} ชิ้น'),
            Text('จำนวนจริงที่ได้: ${reservation.actualQuantity} ชิ้น'),
            Text('จำนวนที่คืน: ${reservation.returnedQuantity} ชิ้น'),
            Text('สถานะ: $thaiStatus'), // ใช้ thaiStatus แทน status
            Text('วันที่จอง: ${reservation.Createdat}'),
            //Text('User ID: ${reservation.userId}'),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPageOne extends StatefulWidget {
  final Product product;
  const ProductDetailPageOne({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';
  final String deleteURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/products/delete';
  final TextEditingController _quantityController = TextEditingController();
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = fetchReservationsForProduct(widget.product.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              print('Deleting product with ID: ${widget.product.id}');
              _deleteProduct(widget.product.id);
            },
            tooltip: 'ลบสินค้า',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.product.imageUrl,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text('ชื่อสินค้า: ${widget.product.name}',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('สินค้าคงเหลือ: ${widget.product.stock} ชิ้น',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('รายการการจอง:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<List<Reservation>>(
                future: _reservationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                            style: TextStyle(color: Colors.red)));
                  } else if (snapshot.hasData) {
                    final reservations = snapshot.data!;
                    if (reservations.isEmpty) {
                      return Center(child: Text('ไม่มีข้อมูลการจอง'));
                    }
                    return ListView.builder(
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];
                        final Map<String, String> statusMap = {
                          'pending': 'รอดำเนินการ',
                          'confirmed': 'ยืนยันแล้ว',
                          'returned': 'คืนแล้ว',
                        };
                        final thaiStatus =
                            statusMap[reservation.status.toLowerCase()] ??
                                reservation.status;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Image.network(
                              reservation.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey);
                              },
                            ),
                            title: Text(
                                '${reservation.productName} (การจอง #${reservation.reserveId})'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'จำนวนที่จอง: ${reservation.quantity} ชิ้น'),
                                Text(
                                    'จำนวนจริงที่ได้: ${reservation.actualQuantity} ชิ้น'),
                                Text(
                                    'จำนวนที่คืน: ${reservation.returnedQuantity} ชิ้น'),
                                Text('สถานะ: $thaiStatus'),
                                Text('User ID: ${reservation.userId}'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('ไม่มีข้อมูล'));
                  }
                },
              ),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'จำนวนที่ต้องการจอง'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _reserveProduct(widget.product.id,
                  int.tryParse(_quantityController.text) ?? 0),
              child: const Text('จองวัสดุ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int productId) async {
    // ignore: unnecessary_null_comparison
    if (productId == 0 || productId == null) {
      _showSnackBar('ไม่พบ ID สินค้าที่ถูกต้อง');
      return;
    }

    final url = Uri.parse(deleteURL);
    try {
      print('Sending DELETE request to: $url with ID: $productId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': productId}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('ลบสินค้าสำเร็จ');
        Navigator.pop(context);
      } else {
        _showSnackBar('ไม่สามารถลบสินค้าได้: ${response.body}');
      }
    } catch (e) {
      print('Error during DELETE request: $e');
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
          _reservationsFuture =
              fetchReservationsForProduct(productId); // อัพเดทข้อมูลหลังจอง
        });
      } else {
        _showSnackBar('ไม่สามารถจองสินค้าได้');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showReservationConfirmation(
      BuildContext context, String productName, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('การจองสำเร็จ'),
        content: Text(
            'คุณได้ทำการจอง "$productName" จำนวน $quantity ชิ้นเรียบร้อยแล้ว!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
