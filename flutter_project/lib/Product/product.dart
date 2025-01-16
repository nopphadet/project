import 'package:flutter/material.dart';
import 'package:flutter_project/HomePage/homePage.dart';

class Product {
  final String name;
  int stock;
  final String imageUrl; // Added image URL property

  Product({required this.name, required this.stock, required this.imageUrl});
}

List<Product> getProductsFromDatabase() {
  // Mock data for demonstration with images
  return [
    Product(
        name: 'สินค้า A',
        stock: 50,
        imageUrl: 'https://via.placeholder.com/150'),
    Product(
        name: 'สินค้า B',
        stock: 20,
        imageUrl: 'https://via.placeholder.com/150'),
    Product(
        name: 'สินค้า C',
        stock: 100,
        imageUrl: 'https://via.placeholder.com/150'),
    Product(
        name: 'สินค้า D',
        stock: 50,
        imageUrl: 'https://via.placeholder.com/150'),
    Product(
        name: 'สินค้า E',
        stock: 20,
        imageUrl: 'https://via.placeholder.com/150'),
    Product(
        name: 'สินค้า F',
        stock: 100,
        imageUrl: 'https://via.placeholder.com/150'),
  ];
}

class ProductListPage extends StatelessWidget {
  final List<Product> products;

  ProductListPage({Key? key})
      : products = getProductsFromDatabase(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // เพิ่มปุ่มกลับ
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            ); // กลับไปหน้าก่อนหน้า
          },
        ),
        title: const Text('รายการสินค้า'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductSearchPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, products[index]);
          },
        ),
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
                product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'สินค้าคงเหลือ: ${product.stock} ชิ้น',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final Product product;

  ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสินค้า'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.product.imageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              Text('ชื่อสินค้า: ${widget.product.name}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('จำนวนในสต็อก: ', style: TextStyle(fontSize: 18)),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'จำนวนสต็อก',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.product.stock = int.parse(_stockController.text);
                  });
                },
                child: const Text('อัปเดตสต็อก'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSearchPage extends StatefulWidget {
  @override
  _ProductSearchPageState createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List<Product> allProducts = getProductsFromDatabase();
  List<Product> filteredProducts = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    filteredProducts = allProducts;
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาสินค้า'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                _filterProducts(query);
              },
              decoration: InputDecoration(
                labelText: 'ค้นหาสินค้า',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          filteredProducts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'ไม่พบสินค้าที่คุณค้นหา',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(
                          context, filteredProducts[index]);
                    },
                  ),
                ),
        ],
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
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(product.name),
        subtitle: Text('สินค้าคงเหลือ: ${product.stock} ชิ้น'),
        trailing: IconButton(
          icon: Icon(Icons.info_outline, color: Colors.red),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
        ),
      ),
    );
  }
}
