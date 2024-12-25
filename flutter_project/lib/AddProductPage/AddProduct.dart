import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  String _stockStatus = 'ใช้งานได้';
  File? _image;

  // Function to add the product
  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        String productNumber = _productNumberController.text;
        String productName = _productNameController.text;
        String category = _categoryController.text;

        // Use tryParse to avoid exceptions
        int? quantity = int.tryParse(_quantityController.text);
        if (quantity == null) {
          throw FormatException("Invalid quantity value");
        }

        double? unitPrice = double.tryParse(_unitPriceController.text);
        if (unitPrice == null) {
          throw FormatException("Invalid unit price value");
        }

        String barcode = _barcodeController.text;
        String stockStatus = _stockStatus;

        // Convert image to base64 if exists
        String? imagePath;
        if (_image != null) {
          imagePath = base64Encode(await _image!.readAsBytes());
        }

        // Create product object
        Map<String, dynamic> product = {
          "product_number": productNumber,
          "product_name": productName,
          "category": category,
          "quantity": quantity,
          "unit_price": unitPrice,
          "barcode": barcode,
          "stock_status": stockStatus,
          "image_path": imagePath,
        };

        // Send data to the API
        var url =
            Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/products');
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(product),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Product Added',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              content: Text(
                'Product added successfully!\nResponse: ${response.body}',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to add product. Response: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid input detected. Error: $e')),
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
                value: _stockStatus, // ค่าต้องตรงกับ items
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
          borderSide: BorderSide(color: Colors.teal),
        ),
        prefixIcon: Icon(icon, color: Colors.teal),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
