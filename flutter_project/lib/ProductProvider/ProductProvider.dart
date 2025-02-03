import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class ProductProvider extends StatefulWidget {
  @override
  _ProductProviderState createState() => _ProductProviderState();
}

class _ProductProviderState extends State<ProductProvider> {
  final TextEditingController _searchController = TextEditingController();
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider/search?name=';

  List<Map<String, dynamic>> _products = [];
  Map<String, int> _selectedQuantities = {};
  Future<void>? _searchFuture;
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchProductData(String searchText) async {
    if (searchText.isEmpty) {
      _showSnackBar('กรุณาป้อนชื่อสินค้าที่ต้องการค้นหา');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$baseURL$searchText');
      print('Fetching: $url'); // Debugging URL
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(data);
            _selectedQuantities.clear();
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

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      _selectedQuantities[productId] = newQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ค้นหาสินค้า'), backgroundColor: Colors.red),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchField(),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator()) // แสดง Loading
                  : _products.isNotEmpty
                      ? _buildProductList()
                      : Center(child: Text("ไม่มีสินค้า")),
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
        labelText: 'ค้นหาสินค้า',
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            setState(() {
              _searchFuture = _fetchProductData(_searchController.text.trim());
            });
          },
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        var product = _products[index];
        String productId = product['product_number'].toString();
        String productName = product['product_name'] ?? 'ไม่ระบุชื่อ';
        String imageUrl =
            product['image_url'] ?? 'https://via.placeholder.com/100';
        int quantity = product['quantity'] ?? 0;
        int selectedQuantity = _selectedQuantities[productId] ?? 0;

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
            subtitle: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: selectedQuantity > 0
                      ? () => _updateQuantity(productId, selectedQuantity - 1)
                      : null,
                ),
                Text('$selectedQuantity', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: selectedQuantity < quantity
                      ? () => _updateQuantity(productId, selectedQuantity + 1)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
