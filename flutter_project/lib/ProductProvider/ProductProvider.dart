import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductProvider extends StatefulWidget {
  @override
  _ProductProvider createState() => _ProductProvider();
}

class _ProductProvider extends State<ProductProvider> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _productName = '';
  int _quantity = 0;
  String? _selectedCategory;
  List<String> _categories = [
    'ทั้งหมด',
    'อาหาร',
    'เครื่องใช้ไฟฟ้า',
    'เครื่องแต่งกาย'
  ];
  bool _isLoading = false;
  final String baseURL = 'https://hfm99nd8-7070.asse.devtunnels.ms';

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchProductData(String barcode) async {
    setState(() => _isLoading = true);

    try {
      var response = await http.get(
        Uri.parse('$baseURL/products?barcode=$barcode'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['product'] != null) {
          setState(() {
            _productName = data['product']['product_name'] ?? 'ไม่ระบุชื่อ';
            _quantity = data['product']['quantity'] ?? 0;
          });
        } else {
          _showSnackBar('ไม่พบข้อมูลสินค้า');
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

  Future<void> _updateProduct() async {
    String quantityText = _quantityController.text.trim();
    if (quantityText.isEmpty || int.tryParse(quantityText) == null) {
      _showSnackBar('กรุณากรอกจำนวนสินค้าให้ถูกต้อง');
      return;
    }

    int newQuantity = int.parse(quantityText);
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> requestBody = {
        'barcode': _barcodeController.text.trim(),
        'quantity': newQuantity,
      };

      var response = await http.put(
        Uri.parse('$baseURL/products/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() => _quantity = data['product']['quantity'] ?? newQuantity);
        _showSnackBar('อัปเดตจำนวนสินค้าเรียบร้อย');
      } else {
        _showSnackBar('ไม่สามารถอัปเดตข้อมูลสินค้าได้: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('จองสินค้า'), backgroundColor: Colors.red),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(),
            SizedBox(height: 16),
            _buildCategoryDropdown(),
            SizedBox(height: 16),
            
            // _buildBarcodeField(),
            // SizedBox(height: 16),
            // if (_isLoading) Center(child: CircularProgressIndicator()),
            // if (!_isLoading && _productName.isNotEmpty)
            //   ..._buildProductDetails(),

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
            _fetchProductData(_searchController.text.trim());
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'ประเภทสินค้า',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'หมายเลขบาร์โค้ดสินค้า',
        border: OutlineInputBorder(),
      ),
      readOnly: false,
    );
  }

  List<Widget> _buildProductDetails() {
    return [
      Text('ชื่อสินค้า: $_productName', style: TextStyle(fontSize: 18)),
      SizedBox(height: 8),
      Text('จำนวนสินค้า: $_quantity', style: TextStyle(fontSize: 18)),
      SizedBox(height: 16),
      TextField(
        controller: _quantityController,
        decoration: InputDecoration(labelText: 'จำนวนสินค้าที่ต้องการแก้ไข'),
        keyboardType: TextInputType.number,
      ),
      SizedBox(height: 16),
      ElevatedButton(
        onPressed: _updateProduct,
        child: Text('อัปเดตจำนวนสินค้า'),
      ),
    ];
  }
}