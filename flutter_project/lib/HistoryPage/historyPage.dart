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
    fetchTransactionHistory();
  }

  Future<void> fetchTransactionHistory() async {
    try {
      final response = await http.put(Uri.parse(
          'https://hfm99nd8-7070.asse.devtunnels.ms/products/update-handler'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactionHistory =
              data.map((e) => Transaction.fromJson(e)).toList();
          filteredHistory = transactionHistory;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
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
        return transaction.productName.contains(query) ||
            transaction.date.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการนำเข้า-นำออก'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ค้นหา',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterTransactions,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                            context, filteredHistory[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          transaction.type == 'incoming'
              ? Icons.add_box
              : Icons.remove_circle_outline,
          color: Colors.red,
        ),
        title: Text(transaction.productName),
        subtitle: Text(
            '${transaction.type == 'incoming' ? 'นำเข้า' : 'นำออก'} - จำนวน: ${transaction.quantity} ชิ้น'),
        trailing: Text(
          transaction.date,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

class Transaction {
  final String productName;
  final int quantity;
  final String type;
  final String date;

  Transaction({
    required this.productName,
    required this.quantity,
    required this.type,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      productName: json['product_name'],
      quantity: json['quantity'],
      type: json['type'],
      date: json['date'],
    );
  }
}
