import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'event_receipt_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';

class ClubRegistrationFormPage extends StatefulWidget {
  final String eventName;
  const ClubRegistrationFormPage({super.key, required this.eventName});

  @override
  State<ClubRegistrationFormPage> createState() => _ClubRegistrationFormPageState();
}

class _ClubRegistrationFormPageState extends State<ClubRegistrationFormPage> {
  String mode = 'online';
  final int fee = 150;
  Uint8List? paymentScreenshotBytes;

  void submit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubReceiptPage(
          eventName: widget.eventName,
          fee: fee,
          paymentMode: mode,
          contactEmail: '',
          contactPhone: 'Thank you for enrolling. Contact the club lead: +91 98765 43210',
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => paymentScreenshotBytes = result.files.single.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Event Enrollment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Enroll with accurate details', style: TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                Text('Enrollment Fee: ₹$fee', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                const Text('Select Payment Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Radio(value: 'online', groupValue: mode, onChanged: (v) => setState(() => mode = v!)), const Text('Online'),
                    const SizedBox(width: 12),
                    Radio(value: 'offline', groupValue: mode, onChanged: (v) => setState(() => mode = v!)), const Text('Offline'),
                  ],
                ),
                const SizedBox(height: 24),
                if (mode == 'online') _buildOnlinePayment() else _buildOfflinePayment(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (mode == 'offline' || paymentScreenshotBytes != null) ? submit : null,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Confirm Registration'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlinePayment() {
    return Center(
      child: Column(
        children: [
          QrImageView(data: 'upi://pay?pa=upi@club&pn=ClubEvent&am=$fee', size: 180),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: pickImage,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Upload Payment Screenshot'),
          ),
          if (paymentScreenshotBytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(paymentScreenshotBytes!, height: 150, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflinePayment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please pay in cash to the organizer.', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 12),
          Text('Contact our offline organizer:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 4),
          Text('📞 +91 98765 43210', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('📧 organizer@clg.edu', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
