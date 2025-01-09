import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class Outfoproduct extends StatefulWidget {
  @override
  _OutfoproductState createState() => _OutfoproductState();
}

class _OutfoproductState extends State<Outfoproduct> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();

  Map<String, dynamic>? _productData;

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _quantityController.dispose();
    _remarksController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  // Search or Load Product
  Future<void> _searchAndLoadProduct() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://hfm99nd8-7070.asse.devtunnels.ms/products/search?barcode=${_searchController.text}'),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productData = data['product'];
          _quantityController.text = _productData?['quantity'].toString() ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบสินค้า: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    }
  }

  // Scan Barcode
  Future<void> scanBarcode() async {
    if (await Permission.camera.request().isGranted) {
      try {
        var result = await BarcodeScanner.scan();
        if (result.rawContent.isNotEmpty) {
          final barcode = result.rawContent;

          // ตรวจสอบว่า barcode ไม่ว่างเปล่า
          if (barcode.isNotEmpty) {
            final response = await http.get(
              Uri.parse(
                  'http://your-server-ip:7070/products/search?barcode=$barcode'),
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              setState(() {
                _productData = data['product'];
                _quantityController.text =
                    _productData?['quantity'].toString() ?? '';
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ไม่พบสินค้า: ${response.body}')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่พบข้อมูลบาร์โค้ด')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('การสแกนบาร์โค้ดล้มเหลว')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning barcode: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ต้องการสิทธิ์การใช้งานกล้อง')),
      );
    }
  }

  // Update Quantity
  Future<void> _updateQuantity() async {
    if (_productData != null) {
      try {
        final response = await http.put(
          Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/products/update'),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "barcode": _productData!['barcode'],
            "quantity": int.tryParse(_quantityController.text) ?? 0,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปเดตจำนวนสำเร็จ')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถอัปเดตข้อมูลได้: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เบิกจ่ายสินค้า'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              if (_productData != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ชื่อสินค้า: ${_productData!['product_name']}'),
                      Text('หมวดหมู่: ${_productData!['category']}'),
                      Text('จำนวนคงเหลือ: ${_productData!['quantity']}'),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              _buildTextField(
                labelText: 'จำนวนที่เบิก',
                hintText: 'กรอกจำนวน',
                keyboardType: TextInputType.number,
                controller: _quantityController,
              ),
              SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'ค้นหาสินค้า',
              hintText: 'ค้นหาด้วยชื่อสินค้า หรือ บาร์โค้ด',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: _searchAndLoadProduct,
        ),
        IconButton(
          icon: Icon(Icons.qr_code_scanner),
          onPressed: scanBarcode,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _updateQuantity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'อัปเดตจำนวน',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'ยกเลิก',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
