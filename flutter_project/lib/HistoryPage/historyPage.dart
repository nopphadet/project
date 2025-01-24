import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Transaction> transactionHistory = [];
  List<Transaction> filteredHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductChangeHistory();
  }

  Future<void> fetchProductChangeHistory() async {
    try {
      final response = await http.get(
        Uri.parse('https://hfm99nd8-7070.asse.devtunnels.ms/product-changes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        setState(() {
          transactionHistory =
              jsonData.map((e) => Transaction.fromJson(e)).toList();
          filteredHistory = transactionHistory;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print(
            'Error: Failed to fetch history with status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _filterTransactions(String query) {
    setState(() {
      filteredHistory = transactionHistory.where((transaction) {
        return transaction.productNumber.contains(query) ||
            transaction.changeType.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการเปลี่ยนแปลงสินค้า'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredHistory.isEmpty
              ? Center(child: Text('ไม่มีประวัติการเปลี่ยนแปลง'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'ค้นหาประวัติ',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _filterTransactions,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(
                                context, filteredHistory[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: Colors.blue,
        ),
        title: Text('Product Number: ${transaction.productNumber}'),
        subtitle: Text(
            '${transaction.changeType} - จาก ${transaction.oldQuantity} เป็น ${transaction.newQuantity} ชิ้น'),
        trailing: Text(
          transaction.createdAt,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

class Transaction {
  final String ProductName;
  final String productNumber;
  final String changeType;
  final int oldQuantity;
  final int newQuantity;
  final String changedBy;
  final String createdAt;

  Transaction({
    required this.ProductName,
    required this.productNumber,
    required this.changeType,
    required this.oldQuantity,
    required this.newQuantity,
    required this.changedBy,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      ProductName: json['product_name'] ?? 'N/A',
      productNumber: json['product_number'] ?? 'N/A',
      changeType: json['change_type'] ?? 'unknown',
      oldQuantity: json['old_quantity'] ?? 0,
      newQuantity: json['new_quantity'] ?? 0,
      changedBy: json['changed_by'] ?? 'N/A',
      createdAt: json['created_at'] ?? '',
    );
  }
}
