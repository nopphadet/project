import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductProvider extends StatefulWidget {
  @override
  _ProductProviderState createState() => _ProductProviderState();
}

class _ProductProviderState extends State<ProductProvider>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final String baseURL =
      'https://hfm99nd8-7070.asse.devtunnels.ms/ProductProvider';

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
      ),
    );
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
            _animationController.forward(from: 0); // รีเซ็ตอนิเมชันเมื่อโหลดใหม่
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
    final userId = prefs.getString("userID");
    final url = Uri.parse('$baseURL/reserve');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      );

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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reservation_id': reservationId,
        }),
      );

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
      builder: (context) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'เลือกจำนวนสินค้า',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'ใส่จำนวน',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey),
              ),
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
              child: const Text(
                'ยืนยัน',
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
          'จองวัสดุ',
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            strokeWidth: 5,
                          ),
                        ),
                      )
                    : _products.isNotEmpty
                        ? FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildProductList(),
                          )
                        : const Center(
                            child: Text(
                              "ไม่มีวัสดุ",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'ค้นหาวัสดุ',
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.red),
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

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / 10),
                  1.0,
                  curve: Curves.easeInOut,
                ),
              ),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      title: Text(
                        '$productName (เหลือ: $quantity)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.red,
                        size: 16,
                      ),
                      onTap: () => _showQuantityDialog(productId),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}