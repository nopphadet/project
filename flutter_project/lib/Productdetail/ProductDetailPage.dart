// import 'package:flutter/material.dart';

// class Product {
//   final String productName;
//   final String imageUrl;
//   final int quantity;

//   Product({
//     required this.productName,
//     required this.imageUrl,
//     required this.quantity,
//   });

//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(
//       productName: json['product_name'],
//       imageUrl: json['image_url'],
//       quantity: json['quantity'],
//     );
//   }
// }

// class ProductDetailPage extends StatelessWidget {
//   final Product product;

//    const ProductDetailPage({Key? key, required this.product}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(product.productName),
//         backgroundColor: Colors.red,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   product.imageUrl.isNotEmpty &&
//                           Uri.tryParse(product.imageUrl)?.hasAbsolutePath ==
//                               true
//                       ? product.imageUrl
//                       : 'https://via.placeholder.com/200',
//                   width: 500,
//                   height: 500,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Icon(Icons.broken_image,
//                         size: 200, color: Colors.grey);
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'ชื่อสินค้า: ${product.productName}',
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'สินค้าคงเหลือ: ${product.quantity} ชิ้น',
//               style: const TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
