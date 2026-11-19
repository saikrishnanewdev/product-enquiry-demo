import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../notifications.dart';
import 'enquiry_chat_screen.dart';

/// CUSTOMER portal: photo + "is this available?" + name + mobile.
class CustomerEnquiryScreen extends StatefulWidget {
  const CustomerEnquiryScreen({super.key});

  @override
  State<CustomerEnquiryScreen> createState() => _CustomerEnquiryScreenState();
}

class _CustomerEnquiryScreenState extends State<CustomerEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _photo;
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _photo = photo);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo of the product.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // 1. Upload the photo to Supabase Storage.
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_photo!.name}';
      await supabase.storage.from('enquiry-photos').upload(
            fileName,
            File(_photo!.path),
          );
      final photoUrl =
          supabase.storage.from('enquiry-photos').getPublicUrl(fileName);

      // 2. Save the enquiry.
      final inserted = await supabase
          .from('enquiries')
          .insert({
            'customer_name': _nameController.text.trim(),
            'mobile': _mobileController.text.trim(),
            'description': _descriptionController.text.trim(),
            'photo_url': photoUrl,
            'status': 'new',
          })
          .select('id')
          .single();
      final enquiryId = inserted['id'] as String;

      // This phone gets a push when the shop replies to this enquiry.
      await PushNotifications.registerToken(
        role: 'customer',
        enquiryId: enquiryId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EnquiryChatScreen(
            enquiryId: enquiryId,
            role: ChatRole.customer,
            title: 'Your enquiry',
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent! The shop will reply here.')),
      );
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: ${e.message}')),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask about a product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photo == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.teal),
                          SizedBox(height: 8),
                          Text('Tap to add a photo of the product'),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_photo!.path), fit: BoxFit.cover),
                          const Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What do you want to ask?',
                hintText: 'e.g. Is this chair available? What is the price?',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Write a short description.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '10-digit mobile number',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Enter a valid mobile number.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send enquiry', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
