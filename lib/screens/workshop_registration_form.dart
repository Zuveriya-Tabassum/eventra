import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'workshop_receipt_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegistrationFormPage extends StatefulWidget {
  final String studentName;
  final String rollNumber;
  final String eventName;
  final String venue;
  final DateTime deadline;

  final int fee;
  final String qrUrl;
  final String offlineContactPhone;
  final String offlineContactEmail;

  const RegistrationFormPage({
    super.key,
    required this.studentName,
    required this.rollNumber,
    required this.eventName,
    required this.venue,
    required this.deadline,
    required this.fee,
    required this.qrUrl,
    required this.offlineContactPhone,
    required this.offlineContactEmail,
  });

  @override
  State<RegistrationFormPage> createState() => _RegistrationFormPageState();
}

class _RegistrationFormPageState extends State<RegistrationFormPage> {
  String mode = 'online';
  Uint8List? paymentScreenshotBytes;
  bool submitting = false;

  Future<void> submit() async {
    if (submitting) return;
    setState(() => submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        setState(() => submitting = false);
        return;
      }

      String? paymentProofUrl;
      if (mode == 'online' && paymentScreenshotBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('payment_proofs/${user.uid}_${widget.eventName}.png');
        await ref.putData(
          paymentScreenshotBytes!,
          SettableMetadata(contentType: 'image/png'),
        );
        paymentProofUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(widget.eventName)
          .set({
        'eventName': widget.eventName,
        'venue': widget.venue,
        'deadline': widget.deadline,
        'status': mode == 'online' ? 'approved' : 'pending',
        'fee': widget.fee,
        'paymentMode': mode,
        'paymentQrUrl': widget.qrUrl,
        'paymentProofUrl': paymentProofUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mode == 'online') {
        final today = DateTime.now();
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, "0")}-${today.day.toString().padLeft(2, "0")}";

        final participationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('participation')
            .doc(todayStr);

        await FirebaseFirestore.instance.runTransaction((trx) async {
          final snap = await trx.get(participationRef);
          final Map<String, dynamic> data =
          snap.exists ? (snap.data() as Map<String, dynamic>) : {};

          final oldWorkshops = (data['workshop'] ?? 0) as int;

          trx.set(
            participationRef,
            {
              'date': todayStr,
              'workshop': oldWorkshops + 1,
              'hackathon': data['hackathon'] ?? 0,
              'quiz': data['quiz'] ?? 0,
            },
            SetOptions(merge: true),
          );
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('events_attended')
            .add({
          'event_name': widget.eventName,
          'event_type': 'Workshop',
          'date': today,
          'venue': widget.venue,
        });

        await FirebaseFirestore.instance.runTransaction((trx) async {
          final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
          final userSnap = await trx.get(userRef);

          final today = DateTime.now();
          final todayStr =
              "${today.year}-${today.month.toString().padLeft(2, "0")}-${today.day.toString().padLeft(2, "0")}";

          if (userSnap.exists) {
            final userData = userSnap.data() as Map<String, dynamic>;
            final currentStreak = userData['streak'] ?? 0;
            final String? lastActivityDate = userData['lastActivityDate'];

            if (lastActivityDate != todayStr) {
              trx.update(userRef, {
                'streak': currentStreak + 1,
                'lastActivityDate': todayStr,
              });
            }
          } else {
            trx.set(
              userRef,
              {
                'streak': 1,
                'lastActivityDate': todayStr,
              },
              SetOptions(merge: true),
            );
          }
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPage(
            eventName: widget.eventName,
            studentName: widget.studentName,
            rollNo: widget.rollNumber,
            fee: widget.fee,
            paymentMode: mode,
            contactEmail: widget.offlineContactEmail,
            contactPhone: widget.offlineContactPhone,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase Error: ${e.message}')),
      );
      setState(() => submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => submitting = false);
    }
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
    final fee = widget.fee;

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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Enrollment Form'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            shadowColor: Colors.teal.shade200,
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
                            const Text(' Select Payment Mode:',
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
                    const Text('🟢 You selected Online Payment Mode',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal)),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          if (widget.qrUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.qrUrl,
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            QrImageView(
                              data:
                              'upi://pay?pa=upi@eventra&pn=EventraWorkshop&am=$fee',
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
                            onPressed: (paymentScreenshotBytes != null &&
                                !submitting)
                                ? submit
                                : null,
                            child: submitting
                                ? const CircularProgressIndicator()
                                : const Text('Submit'),
                          ),
                        ],
                      ),
                    )
                  ] else ...[
                    const Text('🟡 You selected Offline Payment Mode',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Please pay in cash to the organizer.'),
                          const SizedBox(height: 8),
                          const Text('Contact our offline organizer:'),
                          const SizedBox(height: 5),
                          Text('📞 ${widget.offlineContactPhone}'),
                          Text('📧 ${widget.offlineContactEmail}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: !submitting ? submit : null,
                      child: submitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
