import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Product {
  final String name;
  final int stock;
  final String imageUrl;
  final int id;

  Product({
    required this.name,
    required this.stock,
    required this.imageUrl,
    required this.id,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['product_name'] ?? '',
      stock: int.tryParse(json['quantity'].toString()) ??
          0, // แปลง String เป็น int
      imageUrl: json['image_url'] ?? '',
      id: int.tryParse(json['product_id'].toString()) ??
          0, // แปลง String เป็น int
    );
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProductsFromApi();
  }

  Future<List<Product>> fetchProductsFromApi() async {
    const apiUrl = 'https://hfm99nd8-7070.asse.devtunnels.ms/showproducts';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('ไม่สามารถดึงข้อมูลสินค้าได้');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text('รายการวัสดุ', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const Center(child: Text('ไม่มีสินค้าในระบบ'));
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(product: products[index]),
                      ),
                    );
                  },
                  child: _buildProductCard(context, products[index]),
                );
              },
            );
          } else {
            return const Center(child: Text('ไม่มีข้อมูลสินค้า'));
          }
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.network(
          product.imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: 80, color: Colors.grey);
          },
        ),
        title: Text(product.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('สินค้าคงเหลือ: ${product.stock} ชิ้น'),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';
  final TextEditingController _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.product.name, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
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
                style: TextStyle(fontSize: 10)),
            const SizedBox(height: 10),
            Text('สินค้าคงเหลือ: ${widget.product.stock} ชิ้น',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
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

  Future<void> _reserveProduct(int productId, int quantity) async {
    if (quantity <= 0) {
      _showSnackBar('กรุณากรอกจำนวนที่ถูกต้อง');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userID") ?? '0'; // ใช้ user ID จริง ๆ
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
