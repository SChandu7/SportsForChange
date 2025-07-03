import 'dart:io';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'resource.dart';
import 'loginsignup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For content type
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart'; // required for SystemNavigator
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase initialized
  print('✅ BG Message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString('username');

  runApp(
    ChangeNotifierProvider(
      create: (context) => resource(),
      child: MyApp(username: username),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? username;

  MyApp({required this.username});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    setupFCMListener();
  }

  void setupFCMListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Channel for showing important notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  void requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: widget.username == null
          ? LoginPage()
          : SchoolsHomePage(username: widget.username ?? 'nothing'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isPressed = false;
  var obj_popup = popup();
  String temp = "Hello";

  XFile? fil;
  String bgimage = 'assets/bg2.jpeg';

  // String presentUser = resource().PresentWorkingUser;

  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<File> _capturedImages = []; // List to store picked images
  bool isGalleryViewOpen = false;

  Future<void> _pickImage() async {
    try {
      print(temp);
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        final savedImage = await _saveImageToAppDirectory(image);
        setState(() {
          _capturedImages.add(savedImage);
          isGalleryViewOpen = false; // Close gallery view if open
        });
        print("Image picked and saved: ${savedImage.path}");
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<File> _saveImageToAppDirectory(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${directory.path}/$fileName';

    final File imageFile = File(image.path);
    return imageFile.copy(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Container(
        width:
            MediaQuery.of(context).size.width *
            0.69, // Set the width to 50% of the screen
        child: Drawer(
          child: Column(
            children: [
              // Profile Section
              const UserAccountsDrawerHeader(
                accountName: Text("S Chandu"),
                accountEmail: Text("Administrator"),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: AssetImage('assets/imgicon1.png'),
                ),
                decoration: BoxDecoration(color: Colors.blue),
              ),
              // Menu Items
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profile"),
                onTap: () {
                  print("Profile tapped");
                  Navigator.pop(context); // Close the drawer
                },
              ),

              ListTile(
                leading: const Icon(Icons.help),
                title: const Text("Help"),
                onTap: () {
                  print("Help tapped");
                  Navigator.pop(context); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_emergency),
                title: const Text("Raise Query"),
                onTap: () {
                  print("Info tapped");
                  Navigator.pop(context); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  print("Settings tapped");
                  Navigator.pop(context); // Close the drawer
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Sports For Change"),
        backgroundColor: Colors.orangeAccent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the left drawer
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), // Right-side menu icon
            onPressed: () {
              showMenu<int>(
                context: context,
                position: const RelativeRect.fromLTRB(
                  100,
                  80,
                  0,
                  0,
                ), // Adjust position
                items: [
                  const PopupMenuItem(value: 1, child: Text("Log-in")),
                  const PopupMenuItem(value: 2, child: Text("Log-out")),
                  const PopupMenuItem(value: 3, child: Text("Help")),
                ],
              ).then((value) {
                // Handle the selected option
                if (value == 1) {
                  // Action for Option 1

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                } else if (value == 2) {
                  // Action for Option 2
                  print("Option 2 selected");
                  Provider.of<resource>(
                    context,
                    listen: false,
                  ).setLoginDetails('default');
                  BufferPopup bufferPopup = BufferPopup();
                  bufferPopup.showBufferPopup(
                    context,
                    'Logging Out..',
                    resource().PresentWorkingUser,
                    'Logged Out ',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Option 2 selected")),
                  );
                } else if (value == 3) {
                  // Action for Option 2
                  print("Option 3 selected");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Option 3 selected")),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // image: DecorationImage(
          //   image: AssetImage('assets/bg3.jpg'),
          //   fit: BoxFit.cover,
          // ),
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 249, 248, 246),
              Color.fromARGB(255, 129, 175, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 16,
              left: 26,
              child: GestureDetector(
                onDoubleTap: () {
                  if (bgimage == 'assets/bg2.jpeg') {
                    bgimage = 'assets/bg7.jpg';
                  } else if (bgimage == 'assets/bg7.jpg') {
                    bgimage = 'assets/bg31.jpg';
                  } else if (bgimage == 'assets/bg31.jpg') {
                    bgimage = 'assets/bg2.jpeg';
                  }
                  print("Hello World");
                  setState(() {});
                },
                child: Container(
                  height: 280,
                  width: 315,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(bgimage),
                      fit: BoxFit.cover,
                    ),
                    // gradient: const LinearGradient(
                    //   colors: [
                    //     Color.fromARGB(255, 60, 128, 246), // Sky blue color
                    //     Color.fromARGB(255, 122, 81, 20), // Orange color
                    //   ],

                    // End at the right
                    //  ),
                    borderRadius: BorderRadius.circular(8),
                    // Optional: to make the background rounded like the icon
                  ),
                ),
              ),
            ),
            Positioned(
              top: 340,
              left: 43,
              child: Consumer<resource>(
                builder: (context, resource, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 117, 166, 250), // Sky blue color
                          Color.fromARGB(255, 254, 206, 135), // Orange color
                        ],
                        begin: Alignment.centerLeft, // Start from the left
                        end: Alignment.centerRight, // End at the right
                      ),
                      borderRadius: BorderRadius.circular(
                        50,
                      ), // Optional: to make the background rounded like the icon
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white, // Icon color for better visibility
                      ),
                      onPressed: () {
                        String presentUser = resource.PresentWorkingUser;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParticipantListView(),
                          ),
                        );
                        if (presentUser == 'default') {
                          obj_popup.showPopup(context, "Please Login", "");
                        } else if (presentUser == 'student' ||
                            presentUser == 'admin' ||
                            presentUser == 'staff') {
                          // Navigate to OverlappingListView if the user is logged in
                          print(resource.PresentWorkingUser);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParticipantListView(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 340,
              left: 150,
              child: Consumer<resource>(
                builder: (context, resource, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 117, 166, 250), // Sky blue color
                          Color.fromARGB(255, 254, 206, 135), // Orange color
                        ],
                        begin: Alignment.centerLeft, // Start from the left
                        end: Alignment.centerRight, // End at the right
                      ),
                      borderRadius: BorderRadius.circular(
                        50,
                      ), // Optional: to make the background rounded like the icon
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.emoji_events,
                        size: 40,
                        color: Colors.white,
                      ), // Icon color should be white for better visibility
                      onPressed: () {
                        String presentUser = resource.PresentWorkingUser;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AwardsPage()),
                        );
                        if (presentUser == 'default') {
                          obj_popup.showPopup(context, "Please Login", "");
                        } else if (presentUser == 'student' ||
                            presentUser == 'admin' ||
                            presentUser == 'staff') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AwardsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 340,
              right: 45,
              child: Consumer<resource>(
                builder: (context, resource, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 117, 166, 250), // Sky blue color
                          Color.fromARGB(255, 254, 206, 135), // Orange color
                        ],
                        begin: Alignment.centerLeft, // Start from the left
                        end: Alignment.centerRight, // End at the right
                      ),
                      borderRadius: BorderRadius.circular(
                        50,
                      ), // Optional: to make the background rounded like the icon
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.grid_on,
                        size: 40,
                        color: Colors.white,
                      ), // Icon color should be white for better visibility
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SchoolsHomePage(username: 'nothing'),
                          ),
                        );
                        String presentUser = resource.PresentWorkingUser;
                        if (presentUser == 'default') {
                          obj_popup.showPopup(context, "Please Login", "");
                        } else if (presentUser == 'student' ||
                            presentUser == 'admin' ||
                            presentUser == 'staff') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SchoolsHomePage(username: "hello"),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Student and Selection Committee buttons
            Positioned(
              top: 440,
              left: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return ThreeDPushableButton(
                        text: 'Intramurals',
                        buttonColor: Colors.blue,
                        shadowColor: Colors.black,
                        height: 48, // Custom height
                        width: 130,
                        onPressed: () {
                          // Add the desired functionality here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentInterface(),
                            ),
                          );
                          String presentUser = resource.PresentWorkingUser;
                          if (presentUser == 'default') {
                            obj_popup.showPopup(context, "Please Login", "");
                          } else if (presentUser == 'student' ||
                              presentUser == 'staff' ||
                              presentUser == 'admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StudentInterface(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 440,
              right: 37,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return ThreeDPushableButton(
                        text: "Extramurals",
                        buttonColor: Colors.blue,
                        shadowColor: Colors.black,
                        height: 48, // Custom height
                        width: 130,
                        onPressed: () {
                          // Add the desired functionality here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Extramurals(),
                            ),
                          );
                          String presentUser = resource.PresentWorkingUser;
                          if (presentUser == 'default') {
                            obj_popup.showPopup(context, "Please Login", "");
                          } else if (presentUser == 'student' ||
                              presentUser == 'staff' ||
                              presentUser == 'admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Extramurals(),
                              ),
                            );
                            print("3D Button Pressed!");
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            Positioned(
              top: 515,
              right: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return ThreeDPushableButton(
                        text: "Selection Commitee",
                        buttonColor: Colors.redAccent,
                        shadowColor: Colors.black,
                        height: 53, // Custom height
                        width: 285,
                        onPressed: () {
                          // Add the desired functionality here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SelectionCommitteeInterface(),
                            ),
                          );
                          String presentUser = resource.PresentWorkingUser;
                          setState(() {});
                          if (presentUser == 'default') {
                            obj_popup.showPopup(context, "Please Login", "");
                          } else if (presentUser == 'student') {
                            obj_popup.showPopup(context, "Acces Denied", "");
                          } else if (presentUser == 'staff' ||
                              presentUser == 'admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectionCommitteeInterface(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // Add more widgets as needed
                ],
              ),
            ),

            // Bottom navigation buttons
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return buildIconButtonWithBorder(Icons.home, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardPage(),
                          ),
                        );
                      });
                    },
                  ),
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return buildIconButtonWithBorder(Icons.notifications, () {
                        print("notifications button pressed");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(),
                          ),
                        );
                      });
                    },
                  ),
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return buildIconButtonWithBorder(
                        Icons.add_a_photo,
                        () async {
                          print("camera button pressed");
                          {
                            try {
                              ImagePicker imgpic = ImagePicker();
                              fil = await imgpic.pickImage(
                                source: ImageSource.gallery,
                              );
                              setState(() {});

                              BufferPopup bufferPopup = BufferPopup();
                              bufferPopup.showBufferPopup(
                                context,
                                'Uploading...',
                                'Please wait',
                                'Uploaded',
                              );

                              // Perform your image upload or processing logic here
                              await Future.delayed(
                                Duration(seconds: 1),
                              ); // Simulate processing
                              print("Image processing completed");
                              if (fil != null) {
                                print("Image picked: ${fil!.path}");
                              } else {
                                print("No image selected");
                              }
                            } catch (e) {
                              print("Error picking image: $e");
                            }
                          }
                        },
                      );
                    },
                  ),
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return buildIconButtonWithBorder(Icons.info, () {
                        print("Info button pressed");
                        // obj_popup.showPopup(
                        //     context, "Info", "infromation will be dispayed");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InfoPage()),
                        );
                      });
                    },
                  ),
                  Consumer<resource>(
                    builder: (context, resource, child) {
                      return buildIconButtonWithBorder(Icons.settings, () {
                        print("Settings button pressed");

                        // Show the logout confirmation dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                        );
                      });
                    },
                  ),

                  /*  CircleAvatar(
                    radius: 30,

                    backgroundImage:
                        fil != null ? FileImage(File(fil!.path)) : null,
                    // child: CircularButton(
                    // icon: Icons.sports_basketball, onTap: () {}),
                  ), */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildIconButtonWithBorder(IconData icon, VoidCallback onPressed) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(255, 242, 178, 81), // Start color (blue)
          Color.fromARGB(255, 243, 151, 30), // End color (blue accent)
        ],
        begin: Alignment.topLeft, // Gradient starts from top left
        end: Alignment.bottomRight, // Gradient ends at bottom right
      ),
      border: Border.all(
        color: const Color.fromARGB(255, 57, 56, 60),
        width: 2,
      ), // Black border
      borderRadius: BorderRadius.circular(8), // Rounded corners
    ),
    child: IconButton(
      icon: Icon(
        icon,
        size: 30,
        color: const Color.fromARGB(255, 223, 225, 251),
      ), // Icon color is orange
      onPressed: onPressed,
    ),
  );
}

class StudentInterface extends StatelessWidget {
  const StudentInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Interface'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 11,
        itemBuilder: (context, schoolIndex) {
          // Create school name
          final schoolName = 'School ${schoolIndex + 1}';

          // Apply condition for a specific school
          if (schoolName == 'School 5') {
            return Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: ListTile(
                leading: const Icon(
                  Icons.star,
                  color: Colors.amber,
                ), // Different icon
                title: Text(
                  schoolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ), // Custom style
                ),
                subtitle: const Text('Special School!'), // Add extra subtitle
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassesScreen(schoolName: schoolName),
                    ),
                  );
                },
              ),
            );
          }
          /* if (schoolName == 'School 1') {
            return const Card(
                 margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.star,
                    color: Colors.amber), // Different icon
                title: Text(
                  schoolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ), // Custom style
                ),
                subtitle: Text('Special School!'), // Add extra subtitle
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassesScreen(schoolName: schoolName),
                    ),
                  );
                },
              ),
            
                );
          } */

          // Default case for other schools
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.school, color: Colors.indigo),
              title: Text(schoolName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassesScreen(schoolName: schoolName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class Extramurals extends StatelessWidget {
  const Extramurals({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extramurals'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 13, // Total items: 10 matches + 2 semifinals + 1 final
        itemBuilder: (context, index) {
          String title;

          if (index < 10) {
            // Regular match
            if (index == 0) {
              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: ListTile(
                  leading: const Icon(
                    Icons.games,
                    color: Color.fromARGB(255, 2, 6, 30),
                  ),
                  title: const Text(
                    'Match -1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ExtramuralsResults(matchTitle: 'Match -1'),
                      ),
                    );
                  },
                ),
              );
            }
            title = 'Match - ${index + 1}';
          } else if (index == 10) {
            title = 'SemiFinal - 1';
          } else if (index == 11) {
            title = 'SemiFinal - 2';
          } else {
            title = 'Final Match';
          }

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.games, color: Colors.indigo),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExtramuralsResults(matchTitle: title),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ExtramuralsResults extends StatelessWidget {
  final String matchTitle;

  const ExtramuralsResults({super.key, required this.matchTitle});

  @override
  Widget build(BuildContext context) {
    // Placeholder match details
    final team1 = 'Team A';
    final team2 = 'Team B';
    final winners = 'Team A';
    final runners = 'Team B';
    final score = 'Score: 25 - 20';

    return Scaffold(
      appBar: AppBar(
        title: Text(matchTitle),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Match Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Team 1: $team1  --  Winners',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Team 2: $team2  -- Runners',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text(
              score,
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassesScreen extends StatelessWidget {
  final String schoolName;

  const ClassesScreen({super.key, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$schoolName - Classes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, classIndex) {
          // Create class name
          final className = 'Class ${classIndex + 6}';

          // Highlight a specific class
          if (className == 'Class 8') {
            return Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(
                  className,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                subtitle: const Text('Special Class!'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GamesScreen(
                        schoolName: schoolName,
                        className: className,
                      ),
                    ),
                  );
                },
              ),
            );
          } //for particluar seceltion

          // Default case for other classes
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.class_, color: Colors.indigo),
              title: Text(className),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GamesScreen(
                      schoolName: schoolName,
                      className: className,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GamesScreen extends StatelessWidget {
  final String schoolName;
  final String className;

  const GamesScreen({
    super.key,
    required this.schoolName,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final games = [
      'Kabaddi',
      'Football',
      'Volleyball',
      'Kho - Kho',
      'Cricket',
      '100m Run',
      '500m Run',
      'Javelin Throw',
      'Chess',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$className - Games ($schoolName)'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, gameIndex) {
          /* if (schoolName == 'School 2' && className == 'Class 10') {
            return Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.sports, color: Colors.red),
                title: Text(games[gameIndex]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameResultsScreen(
                        schoolName: schoolName,
                        className: className,
                        gameName: games[gameIndex],
                      ),
                    ),
                  );
                },
              ),
            );
          } */
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.sports, color: Colors.indigo),
              title: Text(games[gameIndex]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameResultsScreen(
                      schoolName: schoolName,
                      className: className,
                      gameName: games[gameIndex],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GameResultsScreen extends StatelessWidget {
  final String schoolName;
  final String className;
  final String gameName;

  const GameResultsScreen({
    super.key,
    required this.schoolName,
    required this.className,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    final results = [
      {'rank': 'Winners', 'name': 'John Doe'},
      {'rank': 'Winners', 'name': 'Jane Smith'},
      {'rank': 'Runners', 'name': 'Alice Brown'},
      {'rank': 'Runners', 'name': 'S Chandu'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Results - $gameName ($className, $schoolName)'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          if (schoolName == "School 1" &&
              className == "Class 6" &&
              gameName == "Kabaddi") {
            return Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.red),
                title: Text('Rank: ${results[index]['rank']}'),
                subtitle: Text('Name: ${results[index]['name']}'),
              ),
            );
          }
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: Text('Rank: ${results[index]['rank']}'),
              subtitle: Text('Name: ${results[index]['name']}'),
            ),
          );
        },
      ),
    );
  }
}

class SelectionCommitteeInterface extends StatefulWidget {
  const SelectionCommitteeInterface({super.key});

  @override
  _SelectionCommitteeInterfaceState createState() =>
      _SelectionCommitteeInterfaceState();
}

class _SelectionCommitteeInterfaceState
    extends State<SelectionCommitteeInterface> {
  final TextEditingController _searchController = TextEditingController();
  String selectedGame = 'Kabaddi';
  String selectedCategory = 'Winners';

  final games = [
    'Kabaddi',
    'Football',
    'Volleyball',
    'Kho - Kho',
    'Cricket',
    '100m Run',
    '500m Run',
    'Javelin Throw',
    'Chess',
  ];
  final categories = ['Winners', 'Runners', 'Participants'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selection Committee Interface'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Participant or Event',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedGame,
              items: games.map((game) {
                return DropdownMenuItem(value: game, child: Text(game));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGame = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Game',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Example data count
                itemBuilder: (context, index) {
                  if (selectedGame == "Chess" &&
                      selectedCategory == "Runners") {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.red),
                        title: Text('$selectedGame - Participant ${index + 1}'),
                        subtitle: Text('Category: $selectedCategory'),
                      ),
                    );
                  } //for particular sleection
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.indigo),
                      title: Text('$selectedGame - Participant ${index + 1}'),
                      subtitle: Text('Category: $selectedCategory'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentInterface()),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.bar_chart),
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircularButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 40)),
      ),
    );
  }
}

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  _NewScreenState createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      _isMenuOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Telegram.-Style Sidebar Menu"),
        backgroundColor: const Color.fromARGB(255, 136, 112, 177),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleMenu,
        ),
      ),
      body: Stack(
        children: [
          const Center(
            child: const Text(
              "Main Screen Content",
              style: TextStyle(fontSize: 20),
            ),
          ),
          SlideTransition(
            position: _offsetAnimation,
            child: Container(
              width: 250,
              color: Colors.grey[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UserAccountsDrawerHeader(
                    accountName: const Text(
                      "John Doe",
                      style: TextStyle(color: Colors.white),
                    ),
                    accountEmail: const Text(
                      "john.doe@example.com",
                      style: TextStyle(color: Colors.white70),
                    ),
                    currentAccountPicture: const CircleAvatar(
                      backgroundImage: NetworkImage(
                        "https://via.placeholder.com/150",
                      ), // Replace with user image
                    ),
                    decoration: const BoxDecoration(color: Colors.deepPurple),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      "Settings",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Handle Settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                    ),
                    title: const Text(
                      "Help",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Handle Help tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                    title: const Text(
                      "Info",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Handle Info tap
                    },
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

                SystemNavigator.pop();
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }
}

class ThreeDPushableButton extends StatefulWidget {
  final String text; // Button text
  final VoidCallback onPressed; // Function to handle button press
  final Color buttonColor; // Main button color
  final Color shadowColor; // Shadow color
  final double height; // Button height
  final double width; // Button width

  const ThreeDPushableButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonColor = Colors.blue,
    this.shadowColor = Colors.black,
    this.height = 60, // Default height
    this.width = 200, // Default width
  });

  @override
  _ThreeDPushableButtonState createState() => _ThreeDPushableButtonState();
}

class _ThreeDPushableButtonState extends State<ThreeDPushableButton> {
  final double _shadowHeight = 4; // Height for the shadow
  double _position = 4; // Initial position of the button layer

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _position = 0; // Button pressed
        });
      },
      onTapUp: (_) {
        setState(() {
          _position = _shadowHeight; // Button released
        });
        widget.onPressed(); // Trigger the callback function
      },
      onTapCancel: () {
        setState(() {
          _position = _shadowHeight; // Reset position if tap is canceled
        });
      },
      child: SizedBox(
        height: widget.height + _shadowHeight,
        width: widget.width,
        child: Stack(
          children: [
            // Shadow layer
            Positioned(
              bottom: 0,
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  color: widget.shadowColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            // Button layer
            AnimatedPositioned(
              curve: Curves.easeIn,
              bottom: _position,
              duration: const Duration(milliseconds: 70),
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  color: widget.buttonColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipantListView extends StatelessWidget {
  final List<String> participants = List.generate(
    100,
    (index) => "Participant ${index + 1}",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: const Text('School Participants'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Participants...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Participant List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                return _buildParticipantCard(
                  participantName: participants[index],
                  schoolName: "School ${Random().nextInt(20) + 1}",
                  studentCount: Random().nextInt(500) + 50,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard({
    required String participantName,
    required String schoolName,
    required int studentCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 0, 0).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Section
            //  for every participant photo
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(
                Icons.switch_account, // Change to a person icon.
                size: 32, // Adjust the size of the icon as needed.
                color: Colors.orange, // Icon color.
              ),
            ),

            /*   CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: Text(
                participantName[0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),  */
            const SizedBox(width: 16),
            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "School: $schoolName",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Student ID: $studentCount",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.orangeAccent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 153, 139, 233),
          indicatorWeight: 7.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Today'),
            Tab(text: 'Older'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          NotificationsTab(type: 'New'),
          NotificationsTab(type: 'Today'),
          NotificationsTab(type: 'Older'),
        ],
      ),
    );
  }
}

class NotificationsTab extends StatelessWidget {
  final String type;

  const NotificationsTab({required this.type});

  @override
  Widget build(BuildContext context) {
    // Sample notifications
    List<String> notifications = [];
    if (type == 'New') {
      notifications = [
        'New Notification 1',
        'New Notification 2',
        'New Notification 3',
        'New Notification 4',
        'New Notification 5',
        'New Notification 6',
        'New Notification 7',
      ];
    } else if (type == 'Today') {
      notifications = [
        'Today Notification 1',
        'Today Notification 2',
        'Today Notification 2',
        'Today Notification 2',
      ];
    } else {
      notifications = [
        'Older Notification 1',
        'Older Notification 2',
        'Older Notification 1',
      ];
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return NotificationCard(notification: notifications[index]);
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String notification;

  const NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.notifications, color: Colors.orangeAccent),
        title: Text(
          notification,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("Tap to view details"),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.orangeAccent),
        onTap: () {
          // Handle tap on notification
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on $notification')));
        },
      ),
    );
  }
}

class AwardsPage extends StatelessWidget {
  final List<Award> awards = [
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/imgicon1.png',
    ),
    Award(
      name: 'Jane Smith',
      award: 'Top Scorer',
      prize: 'Gold Medal + \$3000',
      imageUrl: 'assets/bg2.jpeg',
    ),
    Award(
      name: 'Mark Johnson',
      award: 'Best Coach',
      prize: 'Certificate + \$2000',
      imageUrl: 'assets/bg7.jpg',
    ),
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/imgicon1.png',
    ),
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/bg7.jpg',
    ),
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/bg2.jpeg',
    ),
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/bg7.jpg',
    ),
    Award(
      name: 'John Doe',
      award: 'Best Player of the Year',
      prize: 'Trophy + \$5000',
      imageUrl: 'assets/bg7.jpg',
    ),
    // Add more awards as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Awards & Prizes"),
        backgroundColor: const Color.fromARGB(255, 64, 210, 255),
      ),
      body: Column(
        children: [
          // Team Games - Top horizontal slider
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Animated underline
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4, // Thickness of the underline
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 252, 104, 104),
                              Color.fromARGB(255, 145, 174, 249),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Advanced styled text
                    Text(
                      "Team Games",
                      style: TextStyle(
                        fontSize: 28, // Increased font size for emphasis
                        fontWeight:
                            FontWeight.w900, // Bolder weight for standout text
                        color: Colors
                            .black87, // Darker text for a professional look
                        shadows: [
                          Shadow(
                            color: const Color.fromARGB(
                              255,
                              166,
                              22,
                              22,
                            ).withOpacity(0.5),
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                        letterSpacing: 1.5, // Adds spacing between letters
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollUpdateNotification) {
                // Handle high sensitivity scrolling logic here
              }
              return true;
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: awards
                      .map((award) => AwardCard(award: award))
                      .toList(),
                ),
              ),
            ),
          ),
          // Olympic Games - Bottom horizontal slider
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 0,
            ), // Adjust padding as needed
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Animated underline
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4, // Thickness of the underline
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 252, 104, 104),
                              Color.fromARGB(255, 145, 174, 249),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Advanced styled text
                    Text(
                      "Olympic Games",
                      style: TextStyle(
                        fontSize: 28, // Increased font size for emphasis
                        fontWeight:
                            FontWeight.w900, // Bolder weight for standout text
                        color: Colors
                            .black87, // Darker text for a professional look
                        shadows: [
                          Shadow(
                            color: Colors.grey.withOpacity(0.5),
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                        letterSpacing: 1.5, // Adds spacing between letters
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: awards
                      .map((award) => AwardCard(award: award))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Award {
  final String name;
  final String award;
  final String prize;
  final String imageUrl;

  Award({
    required this.name,
    required this.award,
    required this.prize,
    required this.imageUrl,
  });
}

class AwardCard extends StatelessWidget {
  final Award award;

  const AwardCard({required this.award});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle tap event (optional)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tapped on ${award.name}')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: 300,
          width: 200, // You can adjust the width of the card
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(award.imageUrl),
              ),
              const SizedBox(height: 10),
              Text(
                award.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(award.award, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                award.prize,
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.orangeAccent,
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        children: [
          // Profile Settings
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text("Profile Settings"),
            subtitle: Text("Manage your profile information"),
            onTap: () {
              // Navigate to Profile Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSettingsPage()),
              );
            },
          ),
          Divider(),

          // Notification Settings
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.green),
            title: Text("Notification Settings"),
            subtitle: Text("Customize your notification preferences"),
            onTap: () {
              // Navigate to Notification Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsPage(),
                ),
              );
            },
          ),
          Divider(),

          // Privacy Settings
          ListTile(
            leading: Icon(Icons.lock, color: Colors.red),
            title: Text("Privacy Settings"),
            subtitle: Text("Control your privacy preferences"),
            onTap: () {
              // Navigate to Privacy Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
              );
            },
          ),
          Divider(),

          // Theme Settings
          ListTile(
            leading: Icon(Icons.color_lens, color: Colors.purple),
            title: Text("Theme Settings"),
            subtitle: Text("Switch between light and dark modes"),
            onTap: () {
              // Navigate to Theme Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThemeSettingsPage()),
              );
            },
          ),
          Divider(),

          // About Section
          ListTile(
            leading: Icon(Icons.info, color: Colors.teal),
            title: Text("About"),
            subtitle: Text("Learn more about the app"),
            onTap: () {
              // Navigate to About Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}

class ProfileSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Settings"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("Profile Settings Page")),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Settings"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("Notification Settings Page")),
    );
  }
}

class PrivacySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Settings"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("Privacy Settings Page")),
    );
  }
}

class ThemeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Theme Settings"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("Theme Settings Page")),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("About Page")),
    );
  }
}

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sports View"),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: true, // Back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // Two cards per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildDashboardCard(
                    title: "Analytics",
                    icon: Icons.bar_chart,
                    color: Colors.green,
                    onTap: () {
                      // Handle Analytics click
                    },
                  ),
                  _buildDashboardCard(
                    title: "Messages",
                    icon: Icons.message,
                    color: Colors.blue,
                    onTap: () {
                      // Handle Messages click
                    },
                  ),
                  _buildDashboardCard(
                    title: "Tasks",
                    icon: Icons.task,
                    color: Colors.orange,
                    onTap: () {
                      // Handle Tasks click
                    },
                  ),
                  _buildDashboardCard(
                    title: "Settings",
                    icon: Icons.settings,
                    color: Colors.purple,
                    onTap: () {
                      // Handle Settings click
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 0),
      vsync: this,
    );

    // Define Animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animations
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Application"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated About Section
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                color: Colors.blueAccent.withOpacity(0.1),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "SportsForChange Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "This application is designed to provide a seamless and interactive experience for users. "
                      "It offers features like dashboards, notifications, settings, and much more. "
                      "Built with modern design principles and optimized for performance.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Social Media Section with Animated Icons
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 186, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Follow Us",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(
                        FontAwesomeIcons.facebook,
                        Colors.blue,
                        "https://facebook.com",
                      ),
                      const SizedBox(width: 15),
                      _buildSocialIcon(
                        FontAwesomeIcons.twitter,
                        Colors.lightBlue,
                        "https://twitter.com",
                      ), // Twitter icon
                      const SizedBox(width: 15),
                      _buildSocialIcon(
                        FontAwesomeIcons.instagram,
                        Colors.pink,
                        "https://instagram.com",
                      ),
                      const SizedBox(width: 15),
                      _buildSocialIcon(
                        FontAwesomeIcons.linkedin,
                        Colors.blueAccent,
                        "https://linkedin.com",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Footer Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Developed by @Anu_Students",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Disclaimer: All information provided in this application is for informational purposes only. "
                    "The developers are not responsible for any misuse of the content.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "© 2024 SportsForChange. All rights reserved.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        }
      },
      child: CircleAvatar(
        radius: 25,
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, size: 30, color: color),
      ),
    );
  }
}

class SchoolsHomePage extends StatefulWidget {
  final String username;

  SchoolsHomePage({required this.username});
  @override
  _SchoolsHomePageState createState() => _SchoolsHomePageState();
}

class _SchoolsHomePageState extends State<SchoolsHomePage> {
  final List<String> schools = [
    'Heal School',
    'Srmc Krishna',
    'Share & Care',
    'Gannavaram',
    'GannavaramG',
    'Kesarapalli',
    'Davajigudem',
    'Golnapalli',
    'MK Baig MC',
    'KBC ZP Boys',
    'CVR HighSchool',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, Map<String, Map<String, dynamic>>> activities = {};
  int _currentIndex = 0;
  int _selectedIndex = 0;

  late String presentUser;
  bool _showForm = false;
  String _selectedGender = 'Male';
  final List<String> participants = List.generate(
    100,
    (index) => "Participant ${index + 1}",
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dobController = TextEditingController();
  File? _selectedImage;

  List<Map<String, String>> allData = [];
  List<Map<String, String>> filteredData = [];
  DateTime selectedDate = DateTime.now();
  bool showByMonth = false;
  Set<String> activityDates = {};

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void addActivity(String school, String day, Map<String, dynamic> data) {
    setState(() {
      activities.putIfAbsent(school, () => {});
      activities[school]!.putIfAbsent(day, () => data);
    });
  }

  void fetchActivitiesFromBackend() async {
    final url = Uri.parse('http://65.1.134.172:8000/getsportsdailyactivity');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (var item in data) {
          String school = item['school'];
          String rawDate = item['date']; // e.g. "6/8/2025"
          String date = rawDate;

          try {
            List<String> parts = rawDate.split('/');
            if (parts.length == 3) {
              int month = int.parse(parts[0]);
              int day = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              date =
                  "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year}";
            }
          } catch (e) {
            print("Date parse error: $e");
          }

          String time = item['time'];
          String ptName = item['pt_name'];
          String activityType = item['activity_type'];
          String gameName = item['game_name'];

          List<dynamic> images = item['images'];
          List<XFile> imageFiles = images.map<XFile>((img) {
            return XFile(img['image_url']);
          }).toList();

          // Don't call setState for each item — it will slow things down
          activities.putIfAbsent(school, () => {});
          String finalKey = date;
          int count = 1;
          while (activities[school]!.containsKey(finalKey)) {
            count++;
            finalKey = '${date}_$count';
          }

          activities[school]![finalKey] = {
            'ptName': ptName,
            'activityType': activityType,
            'gameName': gameName,
            'time': time,
            'images': imageFiles,
          };
        }

        // ✅ Now call setState ONCE, AFTER loop is complete
        setState(() {
          _flattenData(); // now data exists
          _filterData();
        });
      } else {
        print("Error fetching activities: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  void initState() {
    super.initState();

    fetchActivitiesFromBackend();
    print(activities);
    presentUser = widget.username;
    requestNotificationPermission(); // ✅ Access it like this
  }

  Future<String?> fetchUserProfileImageUrl(String username) async {
    const baseUrl = 'https://djangotestcase.s3.ap-south-1.amazonaws.com/';
    final extensions = ['jpg', 'jpeg', 'png'];

    for (String ext in extensions) {
      final url = '$baseUrl${username}profile.$ext';
      try {
        final response = await http.head(Uri.parse(url));
        if (response.statusCode == 200) {
          return url;
        }
      } catch (_) {
        // continue trying other extensions
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    if (_currentIndex == 0) {
      currentBody = _buildMainSection(context);
    } else if (_currentIndex == 1) {
      currentBody = _buildDataSection();
    } else {
      currentBody = _buildReportSection();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Consumer<resource>(
        builder: (context, resource, child) {
          presentUser = widget.username;
          return Container(
            width: MediaQuery.of(context).size.width * 0.69,
            child: Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(widget.username),
                    accountEmail: Text("Administrator "),

                    currentAccountPicture: FutureBuilder<String?>(
                      future: fetchUserProfileImageUrl(presentUser),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        } else {
                          return const CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/imgicon1.png',
                            ), // fallback
                          );
                        }
                      },
                    ),
                    decoration: BoxDecoration(color: Colors.orangeAccent),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Profile"),
                    onTap: () {
                      print("Profile tapped");
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text("Help"),
                    onTap: () {
                      print("Help tapped");
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_emergency),
                    title: const Text("Raise Query"),
                    onTap: () {
                      print("Info tapped");
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Settings"),
                    onTap: () {
                      print("Settings tapped");
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text("Sports Daily Activities"),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () async {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showMenu<int>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  const PopupMenuItem(value: 1, child: Text("Log-in")),
                  const PopupMenuItem(value: 2, child: Text("Log-out")),
                  const PopupMenuItem(value: 3, child: Text("View")),
                  const PopupMenuItem(value: 3, child: Text("Help")),
                ],
              ).then((value) async {
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                } else if (value == 2) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('username');

                  Provider.of<resource>(
                    context,
                    listen: false,
                  ).setLoginDetails('default');
                  BufferPopup().showBufferPopup(
                    context,
                    'Logging Out..',
                    resource().PresentWorkingUser,
                    'Logged Out ',
                  );
                } else if (value == 3) {
                  // ScaffoldMessenger.of(
                  //   context,
                  // ).showSnackBar(const SnackBar(content: Text("Help tapped")));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                } else if (value == 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Help tapped")));
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => LoginPage()),
                  // );
                }
              });
            },
          ),
        ],
      ),

      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.content_paste),
            label: 'Activities',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Data View'),

          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Participants',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? SizedBox(
              height: 60,
              width: 60,
              child: FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  builder: (_) => ActivityFormSheet(
                    schools: schools,
                    onSubmit: addActivity,
                  ),
                ),
                child: const Icon(Icons.add, size: 36),
              ),
            )
          : null,
    );
  }

  Widget _buildMainSection(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 18),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: schools.map((school) {
        return GestureDetector(
          onTap: () {
            fetchActivitiesFromBackend();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SchoolDetailsPage(
                  schoolName: school,
                  activities: activities[school] ?? {},
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.school, color: Colors.blue, size: 34),
                const SizedBox(height: 12), // FIXED (was SizedBox(width))
                Expanded(
                  child: Text(
                    school,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showStudentIdCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StudentIdCardWidget(), // shown below
        );
      },
    );
  }
  // ...existing code...

  Widget _buildReportSection() {
    TextEditingController _searchController = TextEditingController();
    String _selectedSchool = schools[0]; // Default to first school in the list

    // Use setState to update the selected school
    void _onSchoolChanged(String? value) {
      setState(() {
        _selectedSchool = value!;
      });
    }

    // Filter participants by selected school
    List<Map<String, dynamic>> filteredParticipants = participants
        .map(
          (p) => {
            'name': p,
            'school': _selectedSchool,
            'id': '${Random().nextInt(999) + 100}', // Sample ID
          },
        )
        .where((participant) {
          final query = _searchController.text.trim();
          final matchesID = participant['id']?.contains(query);
          final matchesSchool = participant['school'] == _selectedSchool;
          return matchesID! && matchesSchool;
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      floatingActionButton: !_showForm
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
              child: const Icon(Icons.app_registration, size: 36),
            )
          : null,
      body: Stack(
        children: [
          if (!_showForm)
            Column(
              children: [
                // 🔍 Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by Student ID...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedSchool,
                          onChanged: _onSchoolChanged,
                          decoration: InputDecoration(
                            labelText: 'Select School',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: schools.map((school) {
                            return DropdownMenuItem(
                              value: school,
                              child: Text(school),
                            );
                          }).toList(),
                          menuMaxHeight: 250,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🧍 Participant List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    itemCount: filteredParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = filteredParticipants[index];
                      return _buildParticipantCard(
                        participantName: participant['name'],
                        schoolName: participant['school'],
                        studentCount: int.parse(participant['id']),
                      );
                    },
                  ),
                ),
              ],
            ),

          if (_showForm)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 12,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REGISTRATION FORM',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildField('Full Name'),
                          _buildField('School Name'),
                          _buildDatePickerField('Date of Birth'),
                          SizedBox(height: 7),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField('Age')),
                              SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender.isNotEmpty
                                      ? _selectedGender
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: "Gender",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: ['Male', 'Female']
                                      .map(
                                        (String gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Please select gender'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildField('Address'),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(child: _buildField('Zip Code')),
                              SizedBox(width: 12),
                              Expanded(child: _buildField('Sign Here')),
                            ],
                          ),
                          SizedBox(height: 2),
                          _buildField('Describe Yourself', maxLines: 3),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _showForm = false);
                                },
                                icon: Icon(Icons.close, color: Colors.white),
                                label: Text(
                                  'Close',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Submitted Successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.send, color: Colors.white),
                                label: Text(
                                  'Submit',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
              ),
            ),
        ],
      ),
    );
  }
  // ...existing code...

  void _flattenData() {
    print(activities);
    // add inside the loop for each activity

    allData.clear();
    activities.forEach((school, dateMap) {
      dateMap.forEach((dateKey, details) {
        allData.add({
          'School': school,
          'Date': dateKey,
          'PT Name': details['ptName'] ?? '',
          'Activity': details['activityType'] ?? '',
          'Game': details['gameName'] ?? '',
          'Time': details['time'] ?? '',
        });
        activityDates.add(dateKey);
      });
    });
  }

  void _filterData() {
    final selectedFormat = DateFormat('dd-MM-yyyy');
    final selectedMonth = selectedDate.month;
    final selectedYear = selectedDate.year;

    setState(() {
      if (showByMonth) {
        filteredData = allData.where((item) {
          try {
            final date = selectedFormat.parse(item['Date']!);
            return date.month == selectedMonth && date.year == selectedYear;
          } catch (_) {
            return false;
          }
        }).toList();
      } else {
        final selectedDay = selectedDate.day;
        filteredData = allData.where((item) {
          try {
            final date = selectedFormat.parse(item['Date']!);
            return date.day == selectedDay &&
                date.month == selectedMonth &&
                date.year == selectedYear;
          } catch (_) {
            return false;
          }
        }).toList();
      }
    });
  }

  Future<void> _exportToExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    final headers = ['School', 'Date', 'PT Name', 'Activity', 'Game', 'Time'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    for (int i = 0; i < filteredData.length; i++) {
      final row = filteredData[i];
      for (int j = 0; j < headers.length; j++) {
        sheet.getRangeByIndex(i + 2, j + 1).setText(row[headers[j]]);
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Activity_Summary.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    OpenFile.open(file.path);
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    final headers = ['School', 'Date', 'PT Name', 'Activity', 'Game', 'Time'];
    final data = filteredData
        .map((row) => headers.map((h) => row[h]!).toList())
        .toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) =>
            pw.Table.fromTextArray(headers: headers, data: data),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Activity_Summary.pdf');
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path);
  }

  Widget _buildDataSection() {
    String _viewMode = showByMonth ? 'Months' : 'Days';
    final List<String> _viewOptions = ['Days', 'Months'];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔽 View Mode Selector (Dropdown)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select View Mode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    value: _viewMode,
                    onChanged: (value) async {
                      if (value == 'Days') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2026),
                          helpText: 'Select a date',
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.deepOrange,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            showByMonth = false;
                          });
                          _filterData();
                        }
                      } else {
                        // Custom month picker using a simple dialog
                        final pickedMonth = await showDialog<DateTime>(
                          context: context,
                          builder: (BuildContext context) {
                            DateTime tempSelected = selectedDate;
                            return AlertDialog(
                              title: const Text('Select Month'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 2.5,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: 12,
                                  itemBuilder: (context, index) {
                                    final month = DateTime(2025, index + 1);
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.deepOrangeAccent,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(
                                          DateTime(
                                            selectedDate.year,
                                            index + 1,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        DateFormat.MMM().format(month),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                        if (pickedMonth != null) {
                          setState(() {
                            selectedDate = pickedMonth;
                            showByMonth = true;
                          });
                          _filterData();
                        }
                      }
                    },
                    items: _viewOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 📅 Show selected date/month info below dropdown
            Text(
              showByMonth
                  ? 'Month: ${DateFormat('MMMM yyyy').format(selectedDate)}'
                  : 'Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),
            const Divider(),

            // 📋 Scrollable Data Table (horizontal + vertical)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      'School',
                      'Date',
                      'PT Name',
                      'Activity',
                      'Game',
                      'Time',
                    ].map((h) => DataColumn(label: Text(h))).toList(),
                    rows: filteredData
                        .map(
                          (row) => DataRow(
                            cells: [
                              row['School'],
                              row['Date'],
                              row['PT Name'],
                              row['Activity'],
                              row['Game'],
                              row['Time'],
                            ].map((val) => DataCell(Text(val ?? '-'))).toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ⬇️ Download Options Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              title: const Text('Export to PDF'),
                              onTap: () {
                                Navigator.pop(context);
                                _exportToPDF();
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.table_view,
                                color: Colors.green,
                              ),
                              title: const Text('Export to Excel'),
                              onTap: () {
                                Navigator.pop(context);
                                _exportToExcel();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard({
    required String participantName,
    required String schoolName,
    required int studentCount,
  }) {
    return GestureDetector(
      onTap: () => _showStudentIdCard(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 255, 0, 0).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: const Icon(
                  Icons.switch_account,
                  size: 32,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participantName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "School: $schoolName",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Student ID: $studentCount",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildDatePickerField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );
          if (pickedDate != null) {
            _dobController.text =
                "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
          }
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Select $label' : null,
      ),
    );
  }
}

class StudentIdCardWidget extends StatefulWidget {
  @override
  _StudentIdCardWidgetState createState() => _StudentIdCardWidgetState();
}

class _StudentIdCardWidgetState extends State<StudentIdCardWidget> {
  bool _showAwards = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.deepPurple, width: 2),
        ),
        elevation: 16,
        child: Container(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 28),
                child: Column(
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 36),
                    SizedBox(height: 6),
                    Text(
                      "Chandra Sekhar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      "Kabaddi Player",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Profile Image
              Container(
                transform: Matrix4.translationValues(0.0, -40.0, 0.0),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/cr73.jpg'),
                ),
              ),

              // Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: _showAwards
                      ? [
                          _infoRow('Total Games ', '34'),
                          _infoRow('Wins ', '20'),
                          _infoRow('Losses ', '14'),
                          _infoRow('Goals ', '42'),
                          _infoRow(
                            'Awards ',
                            'Top scorrer  in 2023,Best Player Award 2025',
                          ),
                          _infoRow('Prizes ', '3'),
                          _infoRow('Rating ', '4.5 ⭐'),
                        ]
                      : [
                          _infoRow('Student ID ', '1234'),
                          _infoRow('School ', 'Heal'),
                          _infoRow('Father ', 'Mr. Doe'),
                          _infoRow('Class ', '10-A'),
                          _infoRow('Address ', 'Guntur, AP'),
                        ],
                ),
              ),

              SizedBox(height: 20),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                        label: Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAwards = !_showAwards;
                          });
                        },
                        icon: Icon(Icons.emoji_events, color: Colors.white),
                        label: Text(
                          _showAwards ? 'Back' : 'Awards',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$title:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 6, child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class SchoolDetailsPage extends StatefulWidget {
  final String schoolName;
  final Map<String, Map<String, dynamic>> activities;

  SchoolDetailsPage({required this.schoolName, required this.activities});

  @override
  _SchoolDetailsPageState createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();
  String _searchResult = '';
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _prepareEvents();
  }

  void _prepareEvents() {
    widget.activities.forEach((dateString, data) {
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          final date = DateTime(year, month, day);
          _events[date] = _events[date] ?? [];
          _events[date]!.add(data);
        }
      } catch (e) {
        print('Date parse error: $e');
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _searchDate() {
    FocusScope.of(context).unfocus();
    try {
      final parts = _searchController.text.split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final events = _getEventsForDay(date);

        if (events.isNotEmpty) {
          setState(() {
            _selectedDay = date;
            _focusedDay = date;
          });
        } else {
          setState(() => _searchResult = 'No activity on selected date.');
        }
      }
    } catch (e) {
      setState(() => _searchResult = 'Invalid date format. Use dd-mm-yyyy');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.schoolName} Activities Calendar'),
        backgroundColor: Colors.orangeAccent,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search (dd-mm-yyyy)',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.deepPurple),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _searchDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Go", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            if (_searchResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_searchResult, style: TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.deepPurple,
                      ),
                      SizedBox(width: 6),
                      Text("Available", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  SizedBox(width: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.grey[300],
                      ),
                      SizedBox(width: 6),
                      Text("Unavailable", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  headerStyle: HeaderStyle(
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.deepPurple,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.deepPurple,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(fontWeight: FontWeight.w500),
                    weekendTextStyle: TextStyle(color: Colors.redAccent),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      return SizedBox();
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      final isAvailable = _getEventsForDay(day).isNotEmpty;
                      return Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.deepPurple
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (selectedEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 1.0,
                  vertical: 1,
                ),
                child: Container(
                  width: double.infinity, // Ensures full width
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 6,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PT Name: ${selectedEvents.first['ptName']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Activity Type: ${selectedEvents.first['activityType']}",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Game Name: ${selectedEvents.first['gameName']}",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Time : ${selectedEvents.first['time']}",
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 5),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 15,
                          child: IconButton(
                            icon: Icon(
                              Icons.remove_red_eye,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailsPage(
                                    schoolName: widget.schoolName,
                                    date:
                                        '${_selectedDay!.day.toString().padLeft(2, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.year}',
                                    data: selectedEvents.first,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ActivityDetailsPage extends StatelessWidget {
  final String schoolName;
  final String date;
  final Map<String, dynamic> data;

  ActivityDetailsPage({
    required this.schoolName,
    required this.date,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final List images = data['images'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Activity on $date')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PT Name: ${data['ptName']}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  "Activity Type: ${data['activityType']}",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Game Name: ${data['gameName']}",
                  style: TextStyle(fontSize: 16),
                ),
                Text("Time: ${data['time']}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Text(
                  "Activity Media:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                /// ✅ Use GridView for 3 images per row
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 3 images per row
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final file = images[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        file.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityFormSheet extends StatefulWidget {
  final List<String> schools;
  final Function(String, String, Map<String, dynamic>) onSubmit;

  ActivityFormSheet({required this.schools, required this.onSubmit});

  @override
  _ActivityFormSheetState createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? ptName, activityType, gameName, selectedSchool;
  DateTime? selectedDate;
  String? selectedHour;
  String? selectedAmPm;
  String? selectedDuration;
  bool _isLoading = false;

  List<XFile>? mediaFiles;
  final ImagePicker _picker = ImagePicker();

  void _pickMedia() async {
    final List<XFile>? files = await _picker.pickMultiImage();
    if (files != null) {
      setState(() => mediaFiles = files);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        selectedSchool != null &&
        selectedDate != null &&
        selectedHour != null &&
        selectedAmPm != null &&
        selectedDuration != null) {
      setState(() => _isLoading = true);

      _formKey.currentState!.save();

      final String formattedDate =
          '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}';
      final String formattedTime =
          '$selectedHour:00 $selectedAmPm (${selectedDuration!})';

      var uri = Uri.parse("http://65.1.134.172:8000/postsportsdailyactivity");
      var request = http.MultipartRequest('POST', uri);

      request.fields['pt_name'] = ptName!;
      request.fields['activity_type'] = activityType!;
      request.fields['game_name'] = gameName!;
      request.fields['date'] = formattedDate;
      request.fields['time'] = formattedTime;
      request.fields['school'] = selectedSchool!;

      if (mediaFiles != null && mediaFiles!.isNotEmpty) {
        for (int i = 0; i < mediaFiles!.length; i++) {
          final file = mediaFiles![i];
          final bytes = await file.readAsBytes();
          final mimeType =
              lookupMimeType(file.name) ?? 'application/octet-stream';
          final contentType = MediaType.parse(mimeType);

          final multipartFile = http.MultipartFile.fromBytes(
            'file$i',
            bytes,
            filename:
                '${activityType}_${DateTime.now().millisecondsSinceEpoch}_$i.${file.name.split('.').last}',
            contentType: contentType,
          );

          request.files.add(multipartFile);
        }
      }

      try {
        final response = await request.send();
        setState(() => _isLoading = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resBody = await response.stream.bytesToString();
          print("✅ Activity submitted!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Activity submitted '),
              backgroundColor: Colors.green,
            ),
          );

          // Step 2: Fetch all device tokens
          final tokenResponse = await http.get(
            Uri.parse("http://65.1.134.172:8000/getsportsnotificationtoken/"),
          );

          if (tokenResponse.statusCode == 200) {
            final data = jsonDecode(tokenResponse.body);
            final List<dynamic> tokens = data['tokens'];

            await http.post(
              Uri.parse("http://65.1.134.172:8000/sendnotificationtoall/"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "title": "New PT Activity!",
                "body": "Football Match at 5 PM on Ground A",
              }),
            );

            print("🔔 Notifications sent to ${tokens.length} devices.");
          } else {
            print("⚠️ Failed to fetch tokens: ${tokenResponse.body}");
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Activity submitted & notifications sent!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        } else {
          final err = await response.stream.bytesToString();
          print("❌ Submission error: $err");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to submit activity.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        print("❌ Exception: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error occurred while submitting.  $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, controller) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Add Activity",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDecoration('Select School'),
                        value: selectedSchool,
                        onChanged: (v) => setState(() => selectedSchool = v),
                        items: widget.schools
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        validator: (v) => v == null ? 'Required' : null,
                        menuMaxHeight:
                            200, // optional: limits dropdown popup height
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('PT Name'),
                  onSaved: (v) => ptName = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Activity Type'),
                  onSaved: (v) => activityType = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Game Name'),
                  onSaved: (v) => gameName = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(canvasColor: Colors.white),
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Hour').copyWith(
                            labelStyle: TextStyle(
                              fontSize: 12,
                            ), // 👈 Smaller label
                          ),
                          value: selectedHour,
                          items: List.generate(12, (i) => '${i + 1}')
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedHour = v),
                          validator: (v) => v == null ? 'Required' : null,
                          menuMaxHeight: 200,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDecoration('AM/PM').copyWith(
                          labelStyle: TextStyle(
                            fontSize: 12,
                          ), // 👈 Smaller label
                        ),
                        value: selectedAmPm,
                        items: ['AM', 'PM']
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedAmPm = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDecoration('Duration').copyWith(
                          labelStyle: TextStyle(
                            fontSize: 12,
                          ), // 👈 Smaller label
                        ),
                        value: selectedDuration,
                        items: ['1 Hour', '2 Hours', '4 Hours']
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedDuration = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2026),
                          );
                          if (picked != null)
                            setState(() => selectedDate = picked);
                        },
                        icon: Icon(Icons.calendar_today),
                        label: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue[100],
                          foregroundColor:
                              Colors.black87, // for better contrast
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          textStyle: TextStyle(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickMedia,
                        icon: Icon(Icons.photo_library),
                        label: Text("Select Images"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue[100],
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          textStyle: TextStyle(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (mediaFiles != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("${mediaFiles!.length} images selected"),
                  ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text("Submit Activity"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
