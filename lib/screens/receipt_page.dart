import 'dart:async';
import 'package:flutter/material.dart';

class ReceiptPage extends StatefulWidget {
  final String eventName;
  final int fee;
  final String paymentMode;
  final String contactEmail;
  final String contactPhone;

  const ReceiptPage({
    super.key,
    required this.eventName,
    required this.fee,
    required this.paymentMode,
    required this.contactEmail,
    required this.contactPhone,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      // Fixed navigation - try multiple approaches
      if (mounted) {
        try {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } catch (e) {
          // Fallback navigation
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFE0F2F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text('Enrollment Receipt'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Manual home navigation
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                '🎉 Enrolled Successfully!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 340,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.teal.shade100,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        infoRow('📌 Event:', widget.eventName),
                        infoRow('💰 Fee Paid:', '₹${widget.fee}'),
                        infoRow('💳 Payment Mode:', widget.paymentMode.toUpperCase()),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Organizer Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text('📞 ${widget.contactPhone}'),
                              Text('📧 ${widget.contactEmail}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Redirecting to home page...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          icon: const Icon(Icons.home),
                          label: const Text('Go to Home'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        ),
                      ],
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

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
