import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart'; // ใช้สำหรับตรวจสอบการเชื่อมต่อ
import 'package:shared_preferences/shared_preferences.dart'; // สำหรับจัดการ SharedPreferences

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNumberController =
      TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  String _stockStatus = 'ใช้งานได้';
  File? _image;

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบการเชื่อมต่ออินเทอร์เน็ต')),
        );
        return;
      }

      try {
        String productNumber = _productNumberController.text.trim();
        String productName = _productNameController.text.trim();
        String category = _categoryController.text.trim();
        int? quantity = int.tryParse(_quantityController.text.trim());
        String barcode = _barcodeController.text.trim();
        String stockStatus = _stockStatus;

        // ตรวจสอบว่า quantity ถูกต้อง
        if (quantity == null || quantity < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('จำนวนสินค้าต้องเป็นตัวเลขที่ไม่ติดลบ')),
          );
          return;
        }

        // ตรวจสอบว่ารหัสสินค้าซ้ำในระบบหรือไม่
        var checkUrl = Uri.parse(
            'https://hfm99nd8-7070.asse.devtunnels.ms/check_product/$productNumber');
        var checkResponse = await http.get(checkUrl);
        if (checkResponse.statusCode == 200 && checkResponse.body == 'exists') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('รหัสสินค้านี้มีอยู่ในระบบแล้ว')),
          );
          return;
        }

        // ดึง Token จากที่เก็บข้อมูล (เช่น SharedPreferences หรือจากการล็อกอิน)
        String? token = await getTokenFromSharedPreferences();

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่พบ Token')),
          );
          return;
        }

        // สร้างคำขอแบบ multipart
        var uri =
            Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/products');
        var request = http.MultipartRequest('POST', uri)
          ..fields['product_number'] = productNumber
          ..fields['product_name'] = productName
          ..fields['category'] = category
          ..fields['quantity'] = quantity.toString() // ส่ง quantity เป็นตัวเลข
          ..fields['barcode'] = barcode
          ..fields['stock_status'] = stockStatus;

        // เพิ่ม Authorization token ใน headers
        request.headers['Authorization'] = 'Bearer $token';

        if (_image != null) {
          var imageFile =
              await http.MultipartFile.fromPath('image', _image!.path);
          request.files.add(imageFile);
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('เพิ่มสำเร็จ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('สินค้าเพิ่มเรียบร้อย!'),
              actions: [
                TextButton(
                  child: Text('ตกลง'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เพิ่มสินค้าล้มเหลว: ${response.reasonPhrase}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> scanBarcode() async {
    if (await Permission.camera.request().isGranted) {
      try {
        var result = await BarcodeScanner.scan();
        if (result.rawContent.isNotEmpty) {
          setState(() {
            _barcodeController.text = result.rawContent;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning barcode: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ต้องอนุญาตการเข้าถึงกล้องเพื่อสแกนบาร์โค้ด')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (await Permission.camera.request().isGranted) {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ถ่ายภาพสำเร็จ!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่ได้เลือกภาพ')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ต้องอนุญาตการเข้าถึงกล้องเพื่อถ่ายภาพ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มสินค้า'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _image == null
                      ? Center(
                          child: Text(
                            'กดที่นี่เพื่อถ่ายภาพ',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20),
              _buildTextFormField(
                controller: _productNumberController,
                label: 'รหัสสินค้า',
                icon: Icons.code,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่รหัสสินค้า';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _productNameController,
                label: 'ชื่อสินค้า',
                icon: Icons.production_quantity_limits,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่ชื่อสินค้า';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _categoryController,
                label: 'หมวดหมู่',
                icon: Icons.category,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่ชื่อหมวดหมู่';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _quantityController,
                label: 'จำนวนคงเหลือ',
                icon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่จำนวนสินค้า';
                  }
                  if (int.tryParse(value) == null) {
                    return 'กรุณาใส่จำนวนที่เป็นตัวเลข';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'หมายเลขบาร์โค้ดสินค้า',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: scanBarcode,
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: _barcodeController,
                readOnly: true,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _stockStatus,
                decoration: InputDecoration(
                  labelText: 'สถานะ',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                ),
                items: ['ใช้งานได้', 'สินค้าเสีย'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _stockStatus = newValue!;
                  });
                },
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _addProduct,
                child: Text(
                  'เพิ่มสินค้า',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal),
        ),
        prefixIcon: Icon(icon, color: Colors.teal),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  // ฟังก์ชันดึง Token จาก SharedPreferences (หรือที่จัดเก็บอื่นๆ)
  Future<String?> getTokenFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // หรือต้องระบุชื่อที่เหมาะสม
  }
}
