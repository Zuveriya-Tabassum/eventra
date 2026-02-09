import 'dart:async';
import 'package:flutter/material.dart';
import 'workshop_list.dart';

class ReceiptPage extends StatefulWidget {
  final String eventName;
  final String studentName;
  final String rollNo;
  final int fee;
  final String paymentMode;
  final String contactEmail;
  final String contactPhone;

  const ReceiptPage({
    super.key,
    required this.eventName,
    required this.studentName,
    required this.rollNo,
    required this.fee,
    required this.paymentMode,
    required this.contactEmail,
    required this.contactPhone,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkshopListPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.paymentMode.toLowerCase() == 'online';

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
          title: const Text('Enrollment Receipt'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  '🎉 Enrolled Successfully!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.teal.shade100,
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          infoRow('📌 Event', widget.eventName),
                          // infoRow('👤 Name', widget.studentName),
                          // infoRow('🎓 Roll No', widget.rollNo),
                          infoRow('💰 Fee Paid', '₹${widget.fee}'),
                          infoRow(
                              '💳 Mode', isOnline ? 'Online' : 'Offline'),
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
                                const Text('Organizer Contact',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('📞 ${widget.contactPhone}'),
                                Text('📧 ${widget.contactEmail}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isOnline
                                ? 'Your enrollment is confirmed.'
                                : 'Offline request submitted. Awaiting organizer approval.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isOnline
                                  ? Colors.green[900]
                                  : Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Redirecting to Workshops in 3 seconds...',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkshopListPage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.teal),
                  label: const Text('Go Now',
                      style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
