// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'schools.dart';
import 'resource.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class BufferPopup {
  void showBufferPopup(
    BuildContext context,
    String text1,
    String text2,
    String text3,
  ) async {
    // Show the initial buffering dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text1),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(text2),
            ],
          ),
        );
      },
    );

    // Wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    // Close the initial popup
    Navigator.of(context).pop();

    // Show the success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 0, 0),
            child: Text(text3, style: TextStyle()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the success dialog
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
}

class popup extends StatelessWidget {
  const popup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popup Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showPopup(
              context,
              "popup Example",
              'The content will be displayed here',
            ); // Call the popup function
          },
          child: const Text("Show Popup"),
        ),
      ),
    );
  }

  void showPopup(BuildContext context, String textt, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(textt),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data),
              const SizedBox(height: 10),
              /*  ElevatedButton(
                onPressed: () {
                  print("Popup button pressed!");
                  Navigator.of(context).pop(); // Close the popup
                },
                child: Text("Close Popup"),
              ), */
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _GetUsername = TextEditingController();
  final TextEditingController _GetUserPassword = TextEditingController();
  String? fcmToken;
  var obj_popup = popup();
  bool eye = true;
  String selectedRole = "default";
  String PresentUser = "default";

  String error = '';
  bool isLoading = false;
  void initState() {
    super.initState();

    _requestAllPermissions();
  }

  Future<String?> fetchUserProfileImageUrl(String username) async {
    const imageBaseUrl = 'https://djangotestcase.s3.ap-south-1.amazonaws.com/';

    // Try extensions in order
    final extensions = ['jpg', 'jpeg', 'png'];

    for (String ext in extensions) {
      final imageUrl = '$imageBaseUrl${username}profile.$ext';
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return imageUrl;
        }
      } catch (_) {
        // Continue checking other extensions
      }
    }
    return null; // No valid image found
  }

  Future<void> _requestAllPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      //
      //  Permission.notification,
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(45),
                          bottomRight: Radius.circular(45),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          colors: [
                            Colors.orange.shade900,
                            Colors.orange.shade800,
                            Colors.orange.shade400,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 90),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FadeInUp(
                                  duration: const Duration(milliseconds: 800),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 1100),
                                  child: const Text(
                                    "Welcome Back",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: <Widget>[
                              const SizedBox(height: 60),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1200),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(225, 95, 27, .3),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _GetUsername,
                                          decoration: const InputDecoration(
                                            hintText: "Username eg..test",
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            prefixIcon: Icon(
                                              Icons.verified_user,
                                              color: Colors.orangeAccent,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Username cannot be empty.";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _GetUserPassword,
                                          obscureText: eye,
                                          decoration: InputDecoration(
                                            hintText: "Password eg..test123",
                                            hintStyle: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                            suffix: InkWell(
                                              onTap: () {
                                                setState(() => eye = !eye);
                                              },
                                              child: Icon(
                                                // iconColor: Colors.red,
                                                (eye == true)
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.lightBlue,
                                                size: 22,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.lock,
                                              color: Colors.orangeAccent,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Password cannot be empty.";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1400),
                                child: MaterialButton(
                                  height: 50,
                                  color: Colors.orange[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  onPressed: () async {
                                    final username = _GetUsername.text.trim();
                                    final password = _GetUserPassword.text.trim();

                                    if (username.isEmpty || password.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter username and password.')),
                                      );
                                      return;
                                    }

                                    Provider.of<resource>(context, listen: false).setLoginDetails(username);

                                    setState(() {
                                      isLoading = true;
                                      error = '';
                                    });

                                    try {
                                      final response = await http.post(
                                        Uri.parse('https://api.chandus7.in/assignmentslogin/'),
                                        body: {
                                          'username': username,
                                          'password': password,
                                        },
                                      );

                                      if (response.statusCode == 200) {
                                        Provider.of<resource>(context, listen: false).setLoginDetails(username);
                                        UserSession.saveUsername(username);

                                        final prefs = await SharedPreferences.getInstance();
                                        if (username.isNotEmpty) {
                                          await prefs.setString('username', username);
                                        }

                                        if (!context.mounted) return;

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.success,
                                          animType: AnimType.bottomSlide,
                                          title: 'Welcome $username',
                                          desc: 'You have successfully logged in.',
                                          btnOkText: 'Continue',
                                          btnOkOnPress: () {
                                            if (!context.mounted) return;
                                            if (username.startsWith("pt")) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => ParticularPtPage(username: username)),
                                              );
                                            } else if (username == "admin") {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => AdminDashboard(username: username)),
                                              );
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder: (_) => const AlertDialog(
                                                  title: Text('Admin Approval Required!'),
                                                  content: Text('Please wait for admin approval.'),
                                                ),
                                              );
                                            }
                                          },
                                        ).show();
                                      } else {
                                        setState(() {
                                          error = response.statusCode == 403
                                              ? 'Admin Approval Required!'
                                              : 'Invalid credentials.';
                                        });

                                        if (!context.mounted) return;
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                              response.statusCode == 403
                                                  ? 'Admin Approval Required!'
                                                  : 'Invalid credentials',
                                            ),
                                            content: Text(
                                              response.statusCode == 403
                                                  ? 'Please wait for admin approval.'
                                                  : 'Please enter correct username and password.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Login error: $e');
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Network error. Please try again.')),
                                      );
                                    } finally {
                                      if (mounted) setState(() => isLoading = false);
                                    }
                                  },
                                  child: const Center(
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1450),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GuestInfoPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.orange.shade700, width: 2),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.explore_outlined, color: Colors.orange.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Guest View",
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1500),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUpPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Didn't Sign up? Let's Do..",
                                    style: TextStyle(color: Colors.grey),
                                  ),
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
        },
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  String _selectedRole = "Select Role";
  final TextEditingController _GetUserPassword = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String error = '';
  bool isLoading = false;
  Uint8List? _webImageBytes;

  Future<void> uploadImage(XFile image, BuildContext context) async {
    final fileName = "${_usernameController.text.trim()}profile.jpg"; // ✅

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.chandus7.in/uploadfiletos3/'),
    );

    if (kIsWeb) {
      _webImageBytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _webImageBytes!,
          filename: fileName,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: fileName,
        ),
      );
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        debugPrint('✅ Image uploaded successfully!');
      } else {
        debugPrint('❌ Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
    }

    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.orange.shade900,
                Colors.orange.shade800,
                Colors.orange.shade400,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 75),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 900),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          ),
                          SizedBox(height: 1),
                          Text(
                            "Create a new account",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    FadeInDown(
                      duration: const Duration(milliseconds: 900),
                      child: GestureDetector(
                        onTap: () async {
                          final image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(() {
                              _selectedImage = image;
                            });
                            await uploadImage(
                              image,
                              context,
                            ); // ✅ upload immediately after selection
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null
                              ? (kIsWeb
                                    ? (_webImageBytes != null
                                          ? MemoryImage(_webImageBytes!)
                                          : null)
                                    : FileImage(File(_selectedImage!.path)))
                              : null,
                          child: _selectedImage == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  size: 30,
                                  color: Colors.orange,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _usernameController,
                        hintText: "Username",
                        icon: Icons.verified_user,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        controller: _mobileController,
                        hintText: "Mobile Number",
                        icon: Icons.phone,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      _buildDropdownField(
                        context,
                        title: _selectedRole,
                        icon: Icons.people_outline,
                        items: ["Student", "Admin", "Default"],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      if (_selectedRole == "Student") ...[
                        _buildInputField(
                          controller: _collegeController,
                          hintText: "College Name",
                          icon: Icons.school,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _fieldController,
                          hintText: "Field of Study",
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 15),
                      ],
                      if (_selectedRole == "Admin") ...[
                        _buildInputField(
                          controller: _roleController,
                          hintText: "Role",
                          icon: Icons.business,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _keyController,
                          hintText: "Pass_Key",
                          icon: Icons.key,
                        ),
                        const SizedBox(height: 15),
                      ],
                      _buildInputField(
                        controller: _addressController,
                        hintText: "Address",
                        icon: Icons.home,
                      ),
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: const SizedBox(height: 15),
                      ),
                      _buildInputField(
                        controller: _GetUserPassword,
                        hintText: "Password",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 30),
                      FadeInDown(
                        duration: const Duration(milliseconds: 700),
                        child: MaterialButton(
                          onPressed: () async {
                            // Validate all required fields
                            if (_usernameController.text.trim().isEmpty ||
                                _mobileController.text.trim().isEmpty ||
                                _selectedRole == "Select Role" ||
                                _addressController.text.trim().isEmpty ||
                                _GetUserPassword.text.trim().isEmpty ||
                                (_selectedRole == "Student" &&
                                    (_collegeController.text.trim().isEmpty ||
                                        _fieldController.text
                                            .trim()
                                            .isEmpty)) ||
                                (_selectedRole == "Admin" &&
                                    (_roleController.text.trim().isEmpty ||
                                        _keyController.text.trim().isEmpty)) ||
                                _selectedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "⚠ Please fill all fields and upload an image",
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isLoading = true;
                              error = '';
                            });

                            // ✅ Upload the image
                            await uploadImage(_selectedImage!, context);

                            try {
                              final response = await http.post(
                                Uri.parse(
                                  'https://api.chandus7.in/assignmentssignup/',
                                ),
                                body: {
                                  'username': _usernameController.text.trim(),
                                  'mobilenumber': _mobileController.text.trim(),
                                  'user': _selectedRole,
                                  'college_role': (_selectedRole == "Student")
                                      ? _collegeController.text.trim()
                                      : _roleController.text.trim(),
                                  'feild_key': (_selectedRole == "Student")
                                      ? _fieldController.text.trim()
                                      : _keyController.text.trim(),
                                  'address': _addressController.text.trim(),
                                  'password': _GetUserPassword.text.trim(),
                                },
                              );

                              debugPrint(
                                'Response code: ${response.statusCode}',
                              );
                              debugPrint('Response body: ${response.body}');

                              if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '✅ Signup Successful! Please login.',
                                    ),
                                  ),
                                );
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              } else {
                                setState(() {
                                  error = 'userAlreadyExists or server error.';
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AlertDialog(
                                      title: Text('Invalid Credentials'),
                                      content: Text("Please enter valid data."),
                                    ),
                                  );
                                });
                              }
                            } catch (e) {
                              setState(() {
                                error = 'Network error: $e';
                              });
                              debugPrint('Signup error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signup failed: $e')),
                              );
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                          height: 50,
                          color: Colors.orange.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(225, 95, 27, .3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Colors.orange),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(225, 95, 27, .3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Colors.orange),
          ),
          value: title == "Select Gender" || title == "Select Role"
              ? null
              : title,
          hint: Text(title, style: const TextStyle(color: Colors.grey)),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class GuestInfoPage extends StatefulWidget {
  const GuestInfoPage({super.key});

  @override
  State<GuestInfoPage> createState() => _GuestInfoPageState();
}

class _GuestInfoPageState extends State<GuestInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _primary = Color(0xFF1565C0);
  static const _accent = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHero(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildOverviewTab(),
                _buildWorkflowTab(),
                _buildFeaturesTab(),
                _buildArchitectureTab(),
              ],
            ),
          ),
          _buildLoginCTA(context),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Guest View',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_soccer, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text(
                'SportsForChange',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Empowering youth through sports',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _heroBadge(Icons.phone_android, 'Flutter'),
                  const SizedBox(width: 8),
                  _heroBadge(Icons.storage, 'Django'),
                  const SizedBox(width: 8),
                  _heroBadge(Icons.cloud, 'AWS S3'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const labels = ['Overview', 'Workflow', 'Features', 'Architecture'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _tab.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tab.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab 1: Overview ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _richCard(
          gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
          icon: Icons.lightbulb_rounded,
          iconColor: Colors.amber[800]!,
          title: 'What is SportsForChange?',
          body:
              'A daily activity tracking platform for Physical Trainers assigned to schools. '
              'PTs submit their sports sessions each day — game name, student count, GPS-tagged photos and notes — '
              'giving admins real-time visibility across all schools.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.people,
                value: '11',
                label: 'Physical Trainers',
                color: const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                icon: Icons.school,
                value: '11+',
                label: 'Schools Covered',
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.sports,
                value: 'Daily',
                label: 'Activity Tracking',
                color: const Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                icon: Icons.download,
                value: 'PDF/XLS',
                label: 'Export Reports',
                color: const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionLabel('User Roles'),
        const SizedBox(height: 10),
        _roleCard(
          icon: Icons.sports_handball,
          color: const Color(0xFF1565C0),
          role: 'Physical Trainer (PT)',
          desc: 'Logs in, submits daily activity, captures GPS photos, views own records and profile.',
        ),
        const SizedBox(height: 10),
        _roleCard(
          icon: Icons.admin_panel_settings,
          color: const Color(0xFFE65100),
          role: 'Admin',
          desc: 'Views all school submissions on a calendar, exports data as PDF or Excel, monitors all PTs.',
        ),
      ],
    );
  }

  // ── Tab 2: Workflow ─────────────────────────────────────────────────────────
  Widget _buildWorkflowTab() {
    final steps = [
      _WFStep(
        icon: Icons.login,
        color: const Color(0xFF1565C0),
        title: 'PT Login',
        desc: 'PT logs in with their assigned credentials (pt1–pt11). Session is saved for future opens.',
      ),
      _WFStep(
        icon: Icons.add_location_alt,
        color: const Color(0xFF2E7D32),
        title: 'Submit Daily Activity',
        desc: 'PT fills in game name, student count, activity type, time, and notes for the school session.',
      ),
      _WFStep(
        icon: Icons.camera_alt,
        color: const Color(0xFF6A1B9A),
        title: 'GPS Camera Capture',
        desc: 'Photos are captured via the in-app GPS camera which stamps date, time, address, and lat/lng.',
      ),
      _WFStep(
        icon: Icons.cloud_upload,
        color: const Color(0xFF0277BD),
        title: 'Sync to Backend',
        desc: 'Activity and images are uploaded to the Django API. Images go to AWS S3 storage.',
      ),
      _WFStep(
        icon: Icons.list_alt,
        color: const Color(0xFFE65100),
        title: 'Records Tab',
        desc: 'Submitted activities appear instantly in the PT Records tab, sorted newest first.',
      ),
      _WFStep(
        icon: Icons.calendar_month,
        color: const Color(0xFF00838F),
        title: 'Admin Calendar View',
        desc: 'Admin taps any school, sees a full monthly calendar with blue dots on activity dates.',
      ),
      _WFStep(
        icon: Icons.download,
        color: const Color(0xFF558B2F),
        title: 'Export Reports',
        desc: 'Admin exports all or filtered data as a formatted PDF table or Excel spreadsheet.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _workflowCard(steps[i], i + 1, isLast: i == steps.length - 1),
        ],
      ],
    );
  }

  Widget _workflowCard(_WFStep step, int n, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: step.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: step.color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Icon(step.icon, color: Colors.white, size: 20),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: step.color.withOpacity(0.12), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '$n',
                            style: TextStyle(color: step.color, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(step.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: step.color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(step.desc,
                      style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Features ─────────────────────────────────────────────────────────
  Widget _buildFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _featureCard(
          icon: Icons.camera_enhance,
          color: const Color(0xFF6A1B9A),
          title: 'GPS Camera',
          bullets: [
            'Auto-stamps date, time, address on photo',
            'Lat/lng badge overlay on live preview',
            'Instant capture with onTapDown response',
            'Switch front/back & photo/video modes',
            'Photos saved to local GPS gallery',
          ],
        ),
        const SizedBox(height: 12),
        _featureCard(
          icon: Icons.calendar_month,
          color: const Color(0xFF1565C0),
          title: 'Activity Calendar',
          bullets: [
            'Full monthly grid — swipe to change months',
            'Blue dot marks dates with activity data',
            'Tap date to see all activity cards',
            'Tap card to open detailed activity view',
            'Multiple activities per date supported',
          ],
        ),
        const SizedBox(height: 12),
        _featureCard(
          icon: Icons.insert_chart_outlined,
          color: const Color(0xFF2E7D32),
          title: 'Data & Export',
          bullets: [
            'PDF export: styled table with borders & colors',
            'Excel export: formatted rows with column widths',
            'Filter by school or PT',
            'Per-school and per-PT stats on dashboard',
            'Newest submissions appear instantly',
          ],
        ),
        const SizedBox(height: 12),
        _featureCard(
          icon: Icons.notifications_active,
          color: const Color(0xFFE65100),
          title: 'Push Notifications',
          bullets: [
            'Firebase FCM integration',
            'Device token registered on login',
            'Admin can broadcast to all PTs',
            'Notification on new assignment',
          ],
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> bullets,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(b,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 13, height: 1.45)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Architecture ──────────────────────────────────────────────────────
  Widget _buildArchitectureTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _archLayerCard(
          label: 'Frontend',
          color: const Color(0xFF1565C0),
          icon: Icons.phone_android,
          items: [
            _ArchItem(Icons.flutter_dash, 'Flutter', 'Android & iOS — single codebase'),
            _ArchItem(Icons.palette, 'Material 3', 'UI components & theming'),
            _ArchItem(Icons.hub, 'Provider', 'State management (ChangeNotifier)'),
            _ArchItem(Icons.storage, 'SharedPrefs', 'Session persistence'),
          ],
        ),
        const SizedBox(height: 14),
        _archLayerCard(
          label: 'Backend',
          color: const Color(0xFF2E7D32),
          icon: Icons.dns,
          items: [
            _ArchItem(Icons.code, 'Django REST', 'API Framework — Python 3'),
            _ArchItem(Icons.lock_outline, 'Auth', 'Username + password via SFCUser model'),
            _ArchItem(Icons.api, 'REST API', 'api.chandus7.in — JSON responses'),
            _ArchItem(Icons.data_object, 'Serializers', 'DRF serializers for validation'),
          ],
        ),
        const SizedBox(height: 14),
        _archLayerCard(
          label: 'Data & Storage',
          color: const Color(0xFF6A1B9A),
          icon: Icons.storage,
          items: [
            _ArchItem(Icons.table_chart, 'PostgreSQL', 'Primary relational database'),
            _ArchItem(Icons.cloud, 'AWS S3', 'Image storage — ap-south-1 bucket'),
            _ArchItem(Icons.image, 'boto3', 'S3 upload via Django server'),
            _ArchItem(Icons.link, 'URL refs', 'S3 URLs stored in DB, served directly'),
          ],
        ),
        const SizedBox(height: 14),
        _archLayerCard(
          label: 'Platform Services',
          color: const Color(0xFFE65100),
          icon: Icons.cloud_queue,
          items: [
            _ArchItem(Icons.notifications, 'Firebase FCM', 'Push notifications to PT devices'),
            _ArchItem(Icons.location_on, 'Geolocator', 'GPS position with best accuracy'),
            _ArchItem(Icons.map, 'Geocoding', 'Reverse geocode for address watermark'),
            _ArchItem(Icons.camera, 'camera pkg', 'Native camera with JPEG format'),
          ],
        ),
        const SizedBox(height: 14),
        _archLayerCard(
          label: 'Export & Reporting',
          color: const Color(0xFF00838F),
          icon: Icons.picture_as_pdf,
          items: [
            _ArchItem(Icons.picture_as_pdf, 'pdf pkg', 'Multi-page A4 landscape PDF tables'),
            _ArchItem(Icons.table_view, 'Syncfusion XLSIO', 'Excel with styled rows, column widths'),
            _ArchItem(Icons.open_in_new, 'open_file', 'Open exported file from device storage'),
            _ArchItem(Icons.filter_list, 'Filtering', 'By school, PT, date range'),
          ],
        ),
      ],
    );
  }

  Widget _archLayerCard({
    required String label,
    required Color color,
    required IconData icon,
    required List<_ArchItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
              children: items
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 15, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color.withOpacity(0.9)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom CTA ───────────────────────────────────────────────────────────────
  Widget _buildLoginCTA(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.login, color: Colors.white, size: 20),
          label: const Text(
            'Login as PT',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _richCard({
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: iconColor)),
                const SizedBox(height: 5),
                Text(body,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required Color color,
    required String role,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 5),
                Text(desc,
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WFStep {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _WFStep({required this.icon, required this.color, required this.title, required this.desc});
}

class _ArchItem {
  final IconData icon;
  final String name;
  final String detail;
  const _ArchItem(this.icon, this.name, this.detail);
}
