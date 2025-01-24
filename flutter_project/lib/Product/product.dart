import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String name;
  final int stock;
  final String imageUrl;

  Product({required this.name, required this.stock, required this.imageUrl});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['product_name'],
      stock: json['quantity'],
      imageUrl: json['image_url'],
    );
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProductsFromApi();
  }

  Future<List<Product>> fetchProductsFromApi() async {
    const apiUrl = 'https://hfm99nd8-7070.asse.devtunnels.ms/showproducts';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('ไม่สามารถดึงข้อมูลสินค้าได้');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการสินค้า'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const Center(child: Text('ไม่มีสินค้าในระบบ'));
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(product: products[index]),
                      ),
                    );
                  },
                  child: _buildProductCard(context, products[index]),
                );
              },
            );
          } else {
            return const Center(child: Text('ไม่มีข้อมูลสินค้า'));
          }
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl.isNotEmpty &&
                        Uri.tryParse(product.imageUrl)?.hasAbsolutePath == true
                    ? product.imageUrl
                    : 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 80, color: Colors.grey);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สินค้าคงเหลือ: ${product.stock} ชิ้น',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl.isNotEmpty &&
                          Uri.tryParse(product.imageUrl)?.hasAbsolutePath ==
                              true
                      ? product.imageUrl
                      : 'https://via.placeholder.com/200',
                  width: 500,
                  height: 500,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image,
                        size: 200, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ชื่อสินค้า: ${product.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'สินค้าคงเหลือ: ${product.stock} ชิ้น',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
