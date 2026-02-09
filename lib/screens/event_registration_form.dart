import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'event_receipt_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ClubRegistrationFormPage extends StatefulWidget {

  final String eventName;

  const ClubRegistrationFormPage({
    super.key,


    required this.eventName,
  });

  @override
  State<ClubRegistrationFormPage> createState() =>
      _ClubRegistrationFormPageState();
}

class _ClubRegistrationFormPageState extends State<ClubRegistrationFormPage> {
  String mode = 'online';
  final int fee = 150; // Club event fee
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
          contactPhone:
          'Thank you for enrolling. Contact the club lead: +91 98765 43210',
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => paymentScreenshotBytes = result.files.single.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFFF3E5F5),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.purple.shade50,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, brightness: Brightness.light),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Club Enrollment Form'),
            backgroundColor: Colors.teal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              shadowColor: Colors.tealAccent.shade200,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.eventName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                    const SizedBox(height: 10),
                    const Text('Enroll with accurate details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 30, thickness: 1.5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text('Enrollment Fee: ₹$fee',
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 20),
                              const Text('Select Payment Mode:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Radio(
                                    value: 'online',
                                    groupValue: mode,
                                    onChanged: (val) =>
                                        setState(() => mode = val!),
                                  ),
                                  const Text('Online'),
                                  Radio(
                                    value: 'offline',
                                    groupValue: mode,
                                    onChanged: (val) =>
                                        setState(() => mode = val!),
                                  ),
                                  const Text('Offline'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (mode == 'online') ...[
                      const Text('🟢 Online Payment Selected',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal)),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            QrImageView(
                              data:
                              'upi://pay?pa=upi@club&pn=ClubEvent&am=$fee',
                              size: 180,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Upload Payment Screenshot'),
                            ),
                            if (paymentScreenshotBytes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    paymentScreenshotBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed:
                              paymentScreenshotBytes != null ? submit : null,
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      )
                    ] else ...[
                      const Text('🟡 Offline Payment Selected',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Please pay in cash to the organizer.'),
                            SizedBox(height: 8),
                            Text('Contact our offline organizer:'),
                            SizedBox(height: 5),
                            Text('📞 +91 98765 43210'),
                            Text('📧 organizer@clg.edu'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: submit,
                        child: const Text('Submit'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
