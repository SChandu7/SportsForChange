import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'resource.dart';
import 'main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  String? fcmToken;
  var obj_popup = popup();
  bool eye = true;
  String selectedRole = "default"; // Default role
  String PresentUser = "default";

  // Default credentials for temporary login
  final String _defaultUsername = "admin";
  final String _defaultPassword = "admin123";

  String error = '';
  bool isLoading = false;

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
                                            hintText: "Email or Phone number",
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
                                            hintText: "Password",
                                            hintStyle: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                            suffix: InkWell(
                                              onTap: () {
                                                print("visible");
                                                if (eye == false) {
                                                  eye = true;
                                                } else if (eye == true) {
                                                  eye = false;
                                                }
                                                setState(() {});
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
                                duration: const Duration(milliseconds: 1300),
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 40),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1400),
                                child: MaterialButton(
                                  onPressed: () async {
                                    Provider.of<resource>(
                                      context,
                                      listen: false,
                                    ).setLoginDetails(_GetUsername.text.trim());

                                    // Validate the username and password

                                    setState(() {
                                      isLoading = true;
                                      error = '';
                                    });

                                    try {
                                      final response = await http.post(
                                        Uri.parse(
                                          'http://65.1.134.172:8000/assignmentslogin/',
                                        ),
                                        body: {
                                          'username': _GetUsername.text.trim(),
                                          'password': _GetUserPassword.text
                                              .trim(),
                                        },
                                      );

                                      debugPrint(
                                        'Response code: ${response.statusCode}',
                                      );
                                      debugPrint(
                                        'Response body: ${response.body}',
                                      );

                                      if (response.statusCode == 200) {
                                        final username = _GetUsername.text
                                            .trim();
                                        Provider.of<resource>(
                                          context,
                                          listen: false,
                                        ).setLoginDetails(username);

                                        final userImageUrl =
                                            await fetchUserProfileImageUrl(
                                              username,
                                            );
                                        final prefs =
                                            await SharedPreferences.getInstance();

                                        if (username.isNotEmpty) {
                                          await prefs.setString(
                                            'username',
                                            username,
                                          );

                                          // ✅ Get FCM Token
                                          fcmToken = await FirebaseMessaging
                                              .instance
                                              .getToken();
                                          print("FCM Token: $fcmToken");
                                        }

                                        bool _navigated = false;

                                        try {
                                          final tokenResponse = await http.post(
                                            Uri.parse(
                                              'http://65.1.134.172:8000/postsportsnotificationtoken/',
                                            ),
                                            headers: {
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: jsonEncode({
                                              'username': username,
                                              'device_token': fcmToken,
                                            }),
                                          );

                                          if (tokenResponse.statusCode == 201) {
                                            print(
                                              "✅ FCM token successfully sent to Django.",
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '✅ FCM token successfully sent to Django. ',
                                                ),
                                              ),
                                            );

                                            // Save the token in SharedPreferences
                                            await prefs.setString(
                                              'fcmToken',
                                              fcmToken ?? '',
                                            );
                                            print(
                                              "✅ FCM token saved to SharedPreferences.",
                                            );
                                          } else {
                                            print(
                                              "❌ Token save failed: ${tokenResponse.body}",
                                            );
                                          }
                                        } catch (e) {
                                          print("❌ Token API call error: $e");
                                        }

                                        // Automatically navigate after 3 seconds
                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (!_navigated &&
                                                context.mounted) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SchoolsHomePage(
                                                        username: username,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        );

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.success,
                                          animType: AnimType.bottomSlide,
                                          title: 'Welcome $username  $fcmToken',
                                          desc:
                                              'You have successfully logged in .',
                                          body: Column(
                                            children: [
                                              if (userImageUrl != null)
                                                CircleAvatar(
                                                  radius: 40,
                                                  backgroundImage: NetworkImage(
                                                    userImageUrl,
                                                  ),
                                                )
                                              else
                                                const Icon(
                                                  Icons.account_circle,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Welcome $username! $fcmToken',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          btnOkText: 'Continue',
                                          btnOkOnPress: () {
                                            _navigated = true;
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SchoolsHomePage(
                                                      username: username,
                                                    ),
                                              ),
                                            );
                                          },
                                        ).show();
                                      } else {
                                        setState(() {
                                          error = (response.statusCode == 403)
                                              ? 'Admin Approval Required !'
                                              : 'Invalid credentials .';
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text(
                                                (response.statusCode == 403)
                                                    ? 'Admin Approval Required !'
                                                    : 'Invalid credentials.',
                                              ),
                                              content: Text(
                                                (response.statusCode == 403)
                                                    ? 'Please wait for admin approval.'
                                                    : 'Please Enter Correct Information.',
                                              ),
                                            ),
                                          );
                                        });
                                      }
                                    } catch (e) {
                                      setState(() {
                                        error = 'Network error: $e';
                                      });
                                      debugPrint('Login error: $e');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Login failed: $e'),
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                                  height: 50,
                                  color: Colors.orange[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
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

                              const SizedBox(height: 50),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1500),
                                child: InkWell(
                                  onTap: () {
                                    // Add your desired action here
                                    print(
                                      "Text clicked: Navigate to the Sign-Up Page or Perform Action",
                                    );
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
                              const SizedBox(height: 30),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FadeInUp(
                                      duration: const Duration(
                                        milliseconds: 1600,
                                      ),
                                      child: MaterialButton(
                                        onPressed: () {},
                                        height: 50,
                                        color: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Facebook",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: FadeInUp(
                                      duration: const Duration(
                                        milliseconds: 1700,
                                      ),
                                      child: MaterialButton(
                                        onPressed: () {},
                                        height: 50,
                                        color: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Google",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
      Uri.parse('http://65.1.134.172:8000/uploadfiletos3/'),
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
                                  'http://65.1.134.172:8000/assignmentssignup/',
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
