import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'driver_account_setup.dart';

class DriverProfileUpload extends StatefulWidget {
  const DriverProfileUpload({super.key});

  @override
  State<DriverProfileUpload> createState() => _DriverProfileUploadState();
}

class _DriverProfileUploadState extends State<DriverProfileUpload> {
  File? _profileImage;
  File? _licenseImage;
  final TextEditingController _plateController = TextEditingController();

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(picked.path);
        } else {
          _licenseImage = File(picked.path);
        }
      });
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: Stack(
        children: [
          // Top header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(200),
                  bottomRight: Radius.circular(200),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/driver_registration.png',
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Driver Registration",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Positioned.fill(
            top: 220,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Image Picker
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                      child:
                          _profileImage == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _pickImage(true),
                    child: const Text("Upload Profile Picture"),
                  ),
                  const SizedBox(height: 20),

                  // Plate number input
                  TextField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: "Plate Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // License Image Picker
                  _licenseImage != null
                      ? Image.file(_licenseImage!, height: 150)
                      : const SizedBox(
                        height: 150,
                        child: Center(child: Text("No license image selected")),
                      ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _pickImage(false),
                    child: const Text("Upload Driver License"),
                  ),
                  const SizedBox(height: 30),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Prev"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add form validation or data saving here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverAccountSetup(),
                            ),
                          );
                        },
                        child: const Text("Next"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
