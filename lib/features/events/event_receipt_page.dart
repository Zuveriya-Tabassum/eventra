import 'dart:async';
import 'package:flutter/material.dart';
import 'fests_list.dart';
import 'package:google_fonts/google_fonts.dart';

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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FestsListPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                'Enrolled Successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your registration has been recorded.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _infoRow('Event', widget.eventName),
                      _infoRow('Fee Paid', '₹${widget.fee}'),
                      _infoRow('Payment', widget.paymentMode.toUpperCase()),
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(widget.contactPhone, style: const TextStyle(fontSize: 13)),
                            if (widget.contactEmail.isNotEmpty) Text(widget.contactEmail, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text('Redirecting to events in 3 seconds...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
