import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class ManageProductPage extends StatefulWidget {
  @override
  _ManageProductPageState createState() => _ManageProductPageState();
}

class _ManageProductPageState extends State<ManageProductPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String _productName = '';
  int _quantity = 0;
  String _productId = '';
  bool _isLoading = false;

  final String baseURL = 'https://hfm99nd8-7070.asse.devtunnels.ms';

  // แสดง SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ฟังก์ชันกล้องสแกนบาร์โค้ด
  Future<void> _scanBarcode() async {
    if (await Permission.camera.request().isGranted) {
      try {
        var result = await BarcodeScanner.scan();
        if (result.rawContent.isNotEmpty) {
          setState(() {
            _barcodeController.text = result.rawContent;
          });
          await _fetchProductData(result.rawContent);
        }
      } catch (e) {
        _showSnackBar('เกิดข้อผิดพลาดในการสแกนบาร์โค้ด: $e');
      }
    } else {
      _showSnackBar('กรุณาอนุญาตการเข้าถึงกล้องเพื่อสแกนบาร์โค้ด');
    }
  }

  // ดึงข้อมูลสินค้าเพื่อแก้ไข
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
            _productId = data['product']['product_number'] ?? '';
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

// อัปเดตแก้ไขจำนวนสินค้า
  Future<void> _updateProduct() async {
    String quantityText = _quantityController.text.trim();

    // ตรวจสอบว่าข้อมูลที่กรอกถูกต้องหรือไม่
    if (quantityText.isEmpty || int.tryParse(quantityText) == null) {
      _showSnackBar('กรุณากรอกจำนวนสินค้าให้ถูกต้อง');
      return;
    }

    int newQuantity = int.parse(quantityText);

    // แสดงข้อความโหลด
    setState(() {
      _isLoading = true;
    });

    try {
      // สร้าง body ของคำขอ
      final Map<String, dynamic> requestBody = {
        'barcode': _barcodeController.text.trim(),
        'quantity': newQuantity,
      };

      // พิมพ์ body ที่กำลังจะส่งไปยัง API (สำหรับ debug)
      print('Request Body: ${json.encode(requestBody)}');

      // ส่งคำขอ PUT
      var response = await http.put(
        Uri.parse('$baseURL/products/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      
      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

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
      // ปิดข้อความโหลด
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('จัดการสินค้า'), backgroundColor: Colors.red),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarcodeField(),
            SizedBox(height: 16),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (!_isLoading && _productName.isNotEmpty)
              ..._buildProductDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'หมายเลขบาร์โค้ดสินค้า',
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(Icons.qr_code_scanner),
          onPressed: _scanBarcode,
        ),
      ),
      readOnly: true,
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
