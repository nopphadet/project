import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart'; // ใช้สำหรับตรวจสอบการเชื่อมต่อ

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
            SnackBar(content: Text('จำนวนวัสดุต้องเป็นตัวเลขที่ไม่ติดลบ')),
          );
          return;
        }

        // สร้างคำขอแบบ multipart
        var uri = Uri.parse(
            'https://hfm99nd8-7070.asse.devtunnels.ms/products'); // ใช้ URL API ที่แท้จริง
        var request = http.MultipartRequest('POST', uri)
          ..fields['product_number'] = productNumber
          ..fields['product_name'] = productName
          ..fields['category'] = category
          ..fields['quantity'] = quantity.toString()
          ..fields['barcode'] = barcode
          ..fields['stock_status'] = stockStatus;

        // พิมพ์ข้อมูลที่ส่งไป
        print('Sending request with data:');
        print('Product Number: $productNumber');
        print('Product Name: $productName');
        print('Category: $category');
        print('Quantity: $quantity');
        print('Barcode: $barcode');
        print('Stock Status: $stockStatus');

        if (_image != null) {
          var imageFile =
              await http.MultipartFile.fromPath('image', _image!.path);
          request.files.add(imageFile);
          print('Image Path: ${_image!.path}');
        }

        var response = await request.send().timeout(Duration(seconds: 10));

        // แสดงผลการตอบกลับจาก API
        String responseBody = await response.stream.bytesToString();
        print('Response Body: $responseBody'); // พิมพ์ข้อความตอบกลับจาก API

        if (response.statusCode == 200) {
          _clearForm();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('เพิ่มสำเร็จ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('วัสดุเพิ่มเรียบร้อย!'),
              actions: [
                TextButton(
                  child: Text('ตกลง'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        } else {
          // หาก statusCode ไม่ใช่ 200
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เพิ่มสินค้าล้มเหลว: $responseBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.runtimeType}')),
        );
      }
    }
  }

  void _clearForm() {
    _productNumberController.clear();
    _productNameController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _barcodeController.clear();
    setState(() {
      _image = null;
      _stockStatus = 'ใช้งานได้';
    });
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
        SnackBar(
            content: Text('Camera permission is required to scan barcode')),
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
          SnackBar(content: Text('Image successfully selected!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required to pick image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มวัสดุใหม่', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 250, 2, 2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 30),
              const Text(
                'หมวดหมู่',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: 25),
              _buildTextFormField(
                controller: _productNumberController,
                label: 'รหัสวัสดุ',
                icon: Icons.code,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่รหัสวัสดุ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 19),
              _buildTextFormField(
                controller: _productNameController,
                label: 'ชื่อวัสดุ',
                icon: Icons.production_quantity_limits,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่ชื่อวัสดุ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
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
                              color: const Color.fromARGB(255, 255, 0, 0),
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
                controller: _categoryController,
                label: 'ประเภท',
                icon: Icons.category,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'โปรดใส่ชื่อประเภท';
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
                  labelText: 'หมายเลขบาร์โค้ดวัสดุ',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner,
                        color: const Color.fromARGB(255, 250, 2, 2)),
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
                    borderSide:
                        BorderSide(color: const Color.fromARGB(255, 255, 0, 0)),
                  ),
                ),
                items: ['ใช้งานได้', 'วัสดุเสียหาย'].map((String value) {
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
                  'เพิ่มวัสดุ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom widget for building text fields
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
          borderSide: BorderSide(color: const Color.fromARGB(255, 255, 0, 0)),
        ),
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 250, 2, 2)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
