import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductProvider extends StatefulWidget {
  @override
  _ProductProviderState createState() => _ProductProviderState();
}

class _ProductProviderState extends State<ProductProvider> {
  final TextEditingController _searchController = TextEditingController();
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('จองวัสดุ', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchField(),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _products.isNotEmpty
                      ? _buildProductList()
                      : Center(child: Text("ไม่มีวัสดุ")),
            ),
          ],
        ),
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

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        var product = _products[index];
        String productName = product['product_name'] ?? 'ไม่ระบุชื่อ';
        String imageUrl =
            product['image_url'] ?? 'https://via.placeholder.com/100';
        int quantity = product['quantity'] ?? 0;
        int productId = product['product_id'] ?? 0;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
            ),
            title: Text('$productName (เหลือ: $quantity)'),
            onTap: () => _showQuantityDialog(productId),
          ),
        );
      },
    );
  }
}
