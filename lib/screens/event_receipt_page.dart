import 'dart:async';
import 'package:flutter/material.dart';
import 'events.dart'; // contains ClubEventListPage

class ClubReceiptPage extends StatefulWidget {
  final String eventName;
  final int fee;
  final String paymentMode;
  final String contactEmail;
  final String contactPhone;

  const ClubReceiptPage({
    super.key,
    required this.eventName,
    required this.fee,
    required this.paymentMode,
    required this.contactEmail,
    required this.contactPhone,
  });

  @override
  State<ClubReceiptPage> createState() => _ClubReceiptPageState();
}

class _ClubReceiptPageState extends State<ClubReceiptPage> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to club events page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ClubEventListPage(
            // for receipt flow you usually come from participant side
            isAdmin: false,
            currentUserId: 'participant', // TODO: plug real user id
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF3E5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.purple.shade50,
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                '🎉 Enrolled Successfully!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 340,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.deepPurple.shade100,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        infoRow('📌 Event:', widget.eventName),
                        infoRow('💰 Fee Paid:', '₹${widget.fee}'),
                        infoRow('💳 Payment Mode:',
                            widget.paymentMode.toUpperCase()),
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
                              const Text('Organizer Contact:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text('📞 ${widget.contactPhone}'),
                              Text('📧 ${widget.contactEmail}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
