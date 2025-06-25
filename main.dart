import 'dart:io';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'resource.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart'; // For content type
import 'package:mime/mime.dart';

void main() {
  runApp(
    // Wrap the app with ChangeNotifierProvider to provide Resource globally
    ChangeNotifierProvider(create: (context) => resource(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Global State Management',
      debugShowCheckedModeBanner: false,
      home: SchoolsHomePage(), // Set the initial screen directly
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
                        String presentUser = resource.PresentWorkingUser;
                        if (presentUser == 'default') {
                          obj_popup.showPopup(context, "Please Login", "");
                        } else if (presentUser == 'student' ||
                            presentUser == 'admin' ||
                            presentUser == 'staff') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SchoolsHomePage(),
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
          } //for particluar secelction

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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _GetUsername = TextEditingController();
  final TextEditingController _GetUserPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  var obj_popup = popup();
  bool eye = true;
  String selectedRole = "default"; // Default role
  String PresentUser = "default";

  // Default credentials for temporary login
  final String _defaultUsername = "admin";
  final String _defaultPassword = "admin123";

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
                                            prefixIcon: const Icon(
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
                                  onPressed: () {
                                    // Validate the username and password
                                    if (_GetUsername.text.toString() ==
                                            'student' &&
                                        _GetUserPassword.text.toString() ==
                                            'student123') {
                                      // Successful login: Call the login method
                                      Provider.of<resource>(
                                        context,
                                        listen: false,
                                      ).setLoginDetails('student');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomePage(),
                                        ),
                                      );
                                      // This will update the role and navigate back to Homepage
                                    } else if (_GetUsername.text.toString() ==
                                            'staff' &&
                                        _GetUserPassword.text.toString() ==
                                            'staff123') {
                                      Provider.of<resource>(
                                        context,
                                        listen: false,
                                      ).setLoginDetails('staff');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomePage(),
                                        ),
                                      );
                                    } else if (_GetUsername.text.toString() ==
                                            'admin' &&
                                        _GetUserPassword.text.toString() ==
                                            'admin123') {
                                      Provider.of<resource>(
                                        context,
                                        listen: false,
                                      ).setLoginDetails('admin');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomePage(),
                                        ),
                                      );
                                    } else {
                                      // Show popup for incorrect credentials
                                      obj_popup.showPopup(
                                        context,
                                        "Wrong Credentials",
                                        "Entered Data is Incorrect",
                                      );
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
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  String _selectedGender = "Select Gender";
  String _selectedRole = "Select Role";

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
                          setState(() {});
                          BufferPopup bufferPopup = BufferPopup();
                          bufferPopup.showBufferPopup(
                            context,
                            "Uploading..",
                            "please wait",
                            "Uploaded Complete",
                          );

                          // Perform your image upload or processing logic here
                          await Future.delayed(Duration(seconds: 1));
                          if (image != null) {
                            setState(() {
                              _selectedImage = image;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null
                              ? FileImage(File(_selectedImage!.path))
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
                        hintText: "Full Name",
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        hintText: "Mobile Number",
                        icon: Icons.phone,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      _buildDropdownField(
                        context,
                        title: _selectedGender,
                        icon: Icons.person_outline,
                        items: ["Male", "Female", "Other"],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildDropdownField(
                        context,
                        title: _selectedRole,
                        icon: Icons.people_outline,
                        items: ["Student", "Staff", "Admin"],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(hintText: "Address", icon: Icons.home),
                      const SizedBox(height: 15),
                      _buildInputField(
                        hintText: "Username",
                        icon: Icons.verified_user,
                      ),
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: const SizedBox(height: 15),
                      ),
                      _buildInputField(
                        hintText: "Password",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 30),
                      FadeInDown(
                        duration: const Duration(milliseconds: 700),
                        child: MaterialButton(
                          onPressed: () {
                            // You can add your sign-up logic here
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
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
  @override
  _SchoolsHomePageState createState() => _SchoolsHomePageState();
}

class _SchoolsHomePageState extends State<SchoolsHomePage> {
  final List<String> schools = [for (int i = 1; i <= 11; i++) 'School $i'];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, Map<String, Map<String, dynamic>>> activities = {};

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
          String date = item['date']; // e.g. "2025-06-25"
          String time = item['time']; // e.g. "04:00 PM"
          String ptName = item['pt_name'];
          String activityType = item['activity_type'];
          String gameName = item['game_name'];

          // Combine date + index if needed to avoid overwrite
          String dayKey = date;

          // Extract image URLs as dummy XFile placeholders
          List<dynamic> images = item['images'];
          List<XFile> imageFiles = images.map<XFile>((img) {
            return XFile(img['image_url']); // S3 URL
          }).toList();

          setState(() {
            activities.putIfAbsent(school, () => {});
            // Add or increment index if date already used
            String finalKey = dayKey;
            int count = 1;
            while (activities[school]!.containsKey(finalKey)) {
              count++;
              finalKey = '${dayKey}_$count';
            }

            activities[school]![finalKey] = {
              'ptName': ptName,
              'activityType': activityType,
              'gameName': gameName,
              'time': time,
              'images': imageFiles,
            };
          });
        }
      } else {
        print("Error fetching activities: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchActivitiesFromBackend();

    // Default data for each school
  }

  // ...existing code...
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
        title: const Text("Sports Daily Activites"),
        centerTitle: true,
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
      body: GridView.count(
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
                boxShadow: [
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
                  SizedBox(height: 16),
                  Icon(Icons.school, color: Colors.blue, size: 34),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      school, // Use 'school' instead of 'schools[index]'
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(), // Add .toList() to convert Iterable to List
      ),
      floatingActionButton: SizedBox(
        height: 60, // You can adjust this
        width: 60,
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            builder: (_) =>
                ActivityFormSheet(schools: schools, onSubmit: addActivity),
          ),
          child: Icon(Icons.add, size: 36), // Make icon bigger too
        ),
      ),
    );
  }
}

class SchoolDetailsPage extends StatelessWidget {
  final String schoolName;
  final Map<String, Map<String, dynamic>> activities;

  SchoolDetailsPage({required this.schoolName, required this.activities});

  @override
  Widget build(BuildContext context) {
    final days = activities.keys.toList();

    return Scaffold(
      appBar: AppBar(title: Text('$schoolName Activities')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final data = activities[days[index]]!;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(
                days[index],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(data['activityType']),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityDetailsPage(
                    schoolName: schoolName,
                    date: days[index],
                    data: data,
                  ),
                ),
              ),
            ),
          );
        },
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
                Text("Time : ${data['time']}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Text(
                  "Activity Media:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Row(
                  children: (data['images'] as List<XFile>)
                      .map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              file.path, // ✅ This will be a real S3 URL
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      )
                      .toList(),
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

  // For file type detection
  void _submit() async {
    if (_formKey.currentState!.validate() &&
        selectedSchool != null &&
        selectedDate != null &&
        selectedHour != null &&
        selectedAmPm != null &&
        selectedDuration != null) {
      setState(() => _isLoading = true); // ⏳ Show loading

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

        setState(() => _isLoading = false); // ✅ Hide loading

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resBody = await response.stream.bytesToString();
          print("Activity submitted successfully!");
          print("Response: $resBody");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Activity submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context); // or clear form
        } else {
          final err = await response.stream.bytesToString();
          print("Error: $err");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to submit activity.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false); // ❌ Hide on error
        print("Error submitting activity: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error occurred while submitting.'),
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
