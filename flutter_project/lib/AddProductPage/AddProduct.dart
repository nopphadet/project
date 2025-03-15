import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/animation.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with TickerProviderStateMixin {
  // เปลี่ยนเป็น TickerProviderStateMixin
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNumberController =
      TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  String _stockStatus = 'ใช้งานได้';
  File? _image;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _productNumberController.dispose();
    _productNameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showSnackBar('ไม่พบการเชื่อมต่ออินเทอร์เน็ต');
        return;
      }

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        );

        String productNumber = _productNumberController.text.trim();
        String productName = _productNameController.text.trim();
        String category = _categoryController.text.trim();
        int? quantity = int.tryParse(_quantityController.text.trim());
        String barcode = _barcodeController.text.trim();
        String stockStatus = _stockStatus;

        if (quantity == null || quantity < 0) {
          Navigator.pop(context);
          _showSnackBar('จำนวนวัสดุต้องเป็นตัวเลขที่ไม่ติดลบ');
          return;
        }

        var uri =
            Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/products');
        var request = http.MultipartRequest('POST', uri)
          ..fields['product_number'] = productNumber
          ..fields['product_name'] = productName
          ..fields['category'] = category
          ..fields['quantity'] = quantity.toString()
          ..fields['barcode'] = barcode
          ..fields['stock_status'] = stockStatus;

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

        var response =
            await request.send().timeout(const Duration(seconds: 10));
        String responseBody = await response.stream.bytesToString();
        print('Response Body: $responseBody');

        Navigator.pop(context); // ปิด Loading

        if (response.statusCode == 200) {
          _clearForm();
          _showSuccessDialog();
        } else {
          _showSnackBar('เพิ่มสินค้าล้มเหลว: $responseBody');
        }
      } catch (e) {
        Navigator.pop(context);
        _showSnackBar('เกิดข้อผิดพลาด: ${e.runtimeType}');
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
        _showSnackBar('Error scanning barcode: $e');
      }
    } else {
      _showSnackBar('Camera permission is required to scan barcode');
    }
  }

  Future<void> _pickImage() async {
    if (await Permission.camera.request().isGranted) {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _buttonController.forward().then((_) => _buttonController.reverse());
          _image = File(image.path);
        });
        _showSnackBar('Image successfully selected!');
      } else {
        _showSnackBar('No image selected');
      }
    } else {
      _showSnackBar('Camera permission is required to pick image');
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'เพิ่มสำเร็จ',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'วัสดุเพิ่มเรียบร้อย!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เพิ่มวัสดุใหม่',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 5)],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 30),
                  const Text(
                    'หมวดหมู่',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildTextFormField(
                    controller: _productNumberController,
                    label: 'รหัสวัสดุ',
                    icon: Icons.code,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 19),
                  _buildTextFormField(
                    controller: _productNameController,
                    label: 'ชื่อวัสดุ',
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _image == null ? 1.0 : 1.05,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _image == null
                            ? Center(
                                child: Text(
                                  'กดที่นี่เพื่อถ่ายภาพ',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _categoryController,
                    label: 'ประเภท',
                    icon: Icons.category,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _quantityController,
                    label: 'จำนวนคงเหลือ',
                    icon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'หมายเลขบาร์โค้ดวัสดุ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Colors.red),
                        onPressed: scanBarcode,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: _barcodeController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _stockStatus,
                    decoration: InputDecoration(
                      labelText: 'สถานะ',
                      labelStyle: const TextStyle(
                          color: Colors.black54), // ปรับสี label ให้ตัดกับสีขาว
                      filled: true, // เปิดใช้งานการเติมสีพื้นหลัง
                      fillColor: Colors.white, // ตั้งค่าให้พื้นหลังเป็นสีขาว
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.grey), // เส้นขอบปกติ
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Colors.red, width: 2), // เส้นขอบเมื่อ Focus
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['ใช้งานได้', 'วัสดุเสียหาย'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors
                                .black87, // ปรับสีตัวอักษรให้ชัดเจนบนพื้นขาว
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _stockStatus = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTapDown: (_) => _buttonController.forward(),
                      onTapUp: (_) {
                        _buttonController.reverse();
                        _addProduct();
                      },
                      onTapCancel: () => _buttonController.reverse(),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'เพิ่มวัสดุ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(icon, color: Colors.red),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
