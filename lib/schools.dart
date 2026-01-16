// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use, unnecessary_import

import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sportsdemo/gpscamera.dart';
import 'package:video_player/video_player.dart';
import 'main.dart';
import 'resource.dart';
import 'loginsignup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // required for SystemNavigator
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolsHomePage extends StatefulWidget {
  final String username;

  const SchoolsHomePage({super.key, required this.username});
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

  String presentUser = '';

  bool _showForm = false;
  String _selectedGender = 'Male';
  final List<String> participants = List.generate(
    100,
    (index) => "Participant ${index + 1}",
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dobController = TextEditingController();

  List<Map<String, String>> allData = [];
  List<Map<String, String>> filteredData = [];
  DateTime selectedDate = DateTime.now();
  bool showByMonth = false;
  Set<String> activityDates = {};
  String userRole = "Default";

  void addActivity(String school, String day, Map<String, dynamic> data) {
    setState(() {
      activities.putIfAbsent(school, () => {});
      activities[school]!.putIfAbsent(day, () => data);
    });
  }

  void fetchActivitiesFromBackend() async {
    final url = Uri.parse('http://13.203.219.206:8000/getsportsdailyactivity');
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
                  "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
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
    (widget.username == 'pt1' ||
            widget.username == 'pt2' ||
            widget.username == 'pt3' ||
            widget.username == 'pt4' ||
            widget.username == 'pt5' ||
            widget.username == 'pt6' ||
            widget.username == 'pt7' ||
            widget.username == 'pt8' ||
            widget.username == 'pt9' ||
            widget.username == 'pt10' ||
            widget.username == 'pt11')
        ? userRole = "Pt Sir"
        : null;
    (widget.username == 'admin' || widget.username == 'official')
        ? userRole = "Administrator"
        : null;
    (widget.username == 'test' || widget.username == 'tester')
        ? userRole = "Testing"
        : null;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Consumer<resource>(
        builder: (context, resource, child) {
          presentUser = widget.username;
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.69,
            child: Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(widget.username),
                    accountEmail: Text(userRole),

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
                    title: const Text("Help."),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SportsChatScreen(),
                        ),
                      );
                      // Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_emergency),
                    title: const Text("Raise Query"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDashboard(username: "pt1"),
                        ),
                      ); // Close cthe drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ParticularPtPage(username: "Heal School"),
                        ),
                      );
                      // Close the drawer
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
      children: List.generate(schools.length, (index) {
        String school = schools[index];

        // Determine if the item should be clickable
        bool isClickable = false;
        switch (index) {
          case 0:
            isClickable =
                widget.username == 'pt1' || widget.username == 'admin';
            break;
          case 1:
            isClickable =
                widget.username == 'pt2' || widget.username == 'admin';
            break;
          case 2:
            isClickable =
                widget.username == 'pt3' || widget.username == 'admin';
            break;
          case 3:
            isClickable =
                widget.username == 'pt4' || widget.username == 'admin';
            break;
          case 4:
            isClickable =
                widget.username == 'pt5' || widget.username == 'admin';
            break;
          case 5:
            isClickable =
                widget.username == 'pt6' || widget.username == 'admin';
            break;
          case 6:
            isClickable =
                widget.username == 'pt7' || widget.username == 'admin';
            break;
          case 7:
            isClickable =
                widget.username == 'pt8' || widget.username == 'admin';
            break;
          case 8:
            isClickable =
                widget.username == 'pt9' || widget.username == 'admin';
            break;
          case 9:
            isClickable =
                widget.username == 'pt10' || widget.username == 'admin';
            break;
          case 10:
            isClickable =
                widget.username == 'pt11' || widget.username == 'admin';
            break;
          default:
            isClickable = false;
        }

        return GestureDetector(
          onTap: isClickable
              ? () {
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
                }
              : null,
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
                Icon(
                  Icons.school,
                  color: isClickable ? Colors.blue : Colors.grey,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    school,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isClickable ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
    TextEditingController searchController = TextEditingController();
    String selectedSchool = schools[0]; // Default to first school in the list

    // Use setState to update the selected school
    void onSchoolChanged(String? value) {
      setState(() {
        selectedSchool = value!;
      });
    }

    // Filter participants by selected school
    List<Map<String, dynamic>> filteredParticipants = participants
        .map(
          (p) => {
            'name': p,
            'school': selectedSchool,
            'id': '${Random().nextInt(999) + 100}', // Sample ID
          },
        )
        .where((participant) {
          final query = searchController.text.trim();
          final matchesID = participant['id']?.contains(query);
          final matchesSchool = participant['school'] == selectedSchool;
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
                    controller: searchController,
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
                          value: selectedSchool,
                          onChanged: onSchoolChanged,
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
    String viewMode = showByMonth ? 'Months' : 'Days';
    final List<String> viewOptions = ['Days', 'Months'];

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
                    value: viewMode,
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
                    items: viewOptions
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

class ParticularPtPage extends StatefulWidget {
  final String username;

  const ParticularPtPage({super.key, required this.username});
  @override
  _ParticularPtPageState createState() => _ParticularPtPageState();
}

class _ParticularPtPageState extends State<ParticularPtPage> {
  final Map<String, Map<String, Map<String, dynamic>>> activities = {};

  String? school;
  bool _isScreenReady = false;

  List<String> carouselImages = [];

  final List<String> recentActivities = [
    '29 Sep 2025',
    '28 Sep 2025',
    '25 Sep 2025',
    '20 Sep 2025',
  ];
  List<Map<String, String>> allData = [];
  List<Map<String, String>> filteredData = [];
  DateTime selectedDate = DateTime.now();

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Assign school based on username
    if (widget.username == 'pt1') {
      school = 'Heal School';
    } else if (widget.username == 'pt2') {
      school = 'Srmc Krishna';
    } else if (widget.username == 'pt3') {
      school = 'Share & Care';
    } else if (widget.username == 'pt4') {
      school = 'Gannavaram';
    } else if (widget.username == 'pt5') {
      school = 'GannavaramG';
    } else if (widget.username == 'pt6') {
      school = 'Kesarapalli';
    } else if (widget.username == 'pt7') {
      school = 'Davajigudem';
    } else if (widget.username == 'pt8') {
      school = 'Golnapalli';
    } else if (widget.username == 'pt9') {
      school = 'MK Baig MC';
    } else if (widget.username == 'pt10') {
      school = 'KBC ZP Boys';
    } else if (widget.username == 'pt11') {
      school = 'CVR HighSchool';
    }

    // Carousel assignment
    if (school == 'Heal School') {
      carouselImages = [
        'assets/healimg1.jpg',
        'assets/healimg2.jpg',
        'assets/healimg3.jpg',
      ];
    } else if (school == 'Srmc Krishna') {
      carouselImages = [
        'assets/srmc1.jpg',
        'assets/srmc2.jpg',
        'assets/srmc3.jpg',
      ];
    } else {
      carouselImages = ['assets/demo.jpg'];
    }

    // 🚀 Now assign pages normally (NO async inside setState)
    _pages = [
      buildHomeContent(),
      CameraScreen(cameras: cameras!), // camera screen now safe
      buildHomeContent3(),
    ];

    // Fetch data from backend BEFORE setting ready state
    fetchActivitiesFromBackend();

    // Finally update screen
    setState(() {
      _isScreenReady = true;
    });
  }

  void fetchActivitiesFromBackend() async {
    final url = Uri.parse('http://13.203.219.206:8000/getsportsdailyactivity');
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
                  "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
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

  bool showByMonth = false;
  Set<String> activityDates = {};

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

  void addActivity(String school, String day, Map<String, dynamic> data) {
    setState(() {
      activities.putIfAbsent(school, () => {});
      activities[school]!.putIfAbsent(day, () => data);
    });
  }

  late String presentUser;
  String userRole = "Default";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  void _handleOptionTap(int index) {
    Widget page;

    switch (index) {
      case 0:
        page = SchoolDetailsPage(
          schoolName: school!,
          activities: activities[school] ?? {},
        );
        break;
      case 1:
        page = SportsChatScreen();
        break;
      case 2:
        page = LanguagePreferencePage();
        break;
      case 3:
        page = SettingsPage();
        break;
      case 4:
        page = AboutAppPage();
        break;

      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  int _selectedIndexParticularPtPage = 0;
  late final List<Widget> _pages;

  @override
  Widget build(BuildContext context) {
    if (!_isScreenReady) {
      return Scaffold(
        appBar: AppBar(title: Center(child: const Text("SportsForChange"))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Consumer<resource>(
        builder: (context, resource, child) {
          presentUser = widget.username;
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.69,
            child: Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(widget.username),
                    accountEmail: Text(userRole),

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
                      Navigator.pop(context);
                      setState(() => _selectedIndexParticularPtPage = 2);

                      // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text("Help"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SportsChatScreen(),
                        ),
                      );

                      // Navigator.pop(context); // Close the drawer
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );

                      // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text("About"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutAppPage()),
                      );
                      // Close cthe drawer
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Center(child: const Text('SportsForChange')),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), // Right-side menu icon
            onPressed: () {
              showMenu<int>(
                context: context,
                position: const RelativeRect.fromLTRB(
                  70,
                  60,
                  0,
                  0,
                ), // Adjust position
                items: [
                  const PopupMenuItem(value: 1, child: Text("Log-in")),
                  const PopupMenuItem(value: 2, child: Text("Log-out")),
                  const PopupMenuItem(value: 3, child: Text("Help")),
                ],
              ).then((value) async {
                // Handle the selected option
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                  // Action for Option 1
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
                  // Action for Option 2
                } else if (value == 3) {
                  // Action for Option 2
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SportsChatScreen()),
                  );
                }
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndexParticularPtPage,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) =>
            setState(() => _selectedIndexParticularPtPage = index),

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports),
            label: "Activities",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: _pages[_selectedIndexParticularPtPage],

      // ✅ Floating Action Button FIXED (placed correctly)
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          builder: (_) =>
              ActivityFormSheet(schools: schools, onSubmit: addActivity),
        ),
        child: const Icon(Icons.add, size: 36),
      ),
    );
  }

  Widget buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ---------------- Carousel ----------------
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: carouselImages.map((image) {
              return Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ---------------- School Data ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    school ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Welcome PtSir', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Heal Paradise School offers excellent education and sports facilities to nurture students into well-rounded individuals.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- Sports / Activities ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // Months Grid 3x4
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: months.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SchoolDetailsPage(
                              schoolName: school!,
                              activities: activities[school] ?? {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Center(
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomeContent2() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ---------------- Carousel ----------------
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: carouselImages.map((image) {
              return Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ---------------- School Data ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    school ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Welcome2 PtSir', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Heal Paradise School offers excellent education and sports facilities to nurture students into well-rounded individuals.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- Sports / Activities ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // Months Grid 3x4
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: months.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SchoolDetailsPage(
                              schoolName: school!,
                              activities: activities[school] ?? {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Center(
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomeContent3() {
    final options = [
      {"title": "My Activities", "icon": Icons.task_alt_rounded},
      {"title": "Support & Helpdesk", "icon": Icons.support_agent_rounded},
      {"title": "Language Preference", "icon": Icons.language_rounded},
      {"title": "Settings", "icon": Icons.settings_outlined},
      {"title": "About App", "icon": Icons.info_outline},
    ];

    return Column(
      children: [
        const SizedBox(height: 8),

        // -------- HEADER GRADIENT SECTION --------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D92FF), Color(0xFF05A64C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Avatar
              FutureBuilder<String?>(
                future: fetchUserProfileImageUrl(widget.username),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/imgicon1.png'),
                    );
                  }
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Welcome Text
              const Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Login/Register Button
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.username,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // -------- OPTIONS LIST --------
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final item = options[index];
              return InkWell(
                onTap: () => _handleOptionTap(index),

                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE9F4FF),
                        child: Icon(
                          item["icon"] as IconData,
                          size: 20,
                          color: const Color(0xFF015AA5),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item["title"] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StudentIdCardWidget extends StatefulWidget {
  const StudentIdCardWidget({super.key});

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
        child: SizedBox(
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

  const SchoolDetailsPage({
    super.key,
    required this.schoolName,
    required this.activities,
  });

  @override
  _SchoolDetailsPageState createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();
  String _searchResult = '';
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

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
          setState(() => _searchResult = 'No activity on selected date. ');
        }
      }
    } catch (e) {
      setState(() => _searchResult = 'Invalid date format. Use dd-mm-yyyy');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.activities);
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
                      Text(' Available', style: TextStyle(fontSize: 14)),
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
                child: SizedBox(
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
                              for (var i in selectedEvents.first['images']) {
                                debugPrint('IMAGE TYPE: ${i.runtimeType}');
                                debugPrint('IMAGE PATH: ${i.path}');
                              }

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

  const ActivityDetailsPage({
    super.key,
    required this.schoolName,
    required this.date,
    required this.data,
  });
  void initState() {
    fetchActivitiesFromBackend();
  }

  void fetchActivitiesFromBackend() async {
    final url = Uri.parse('http://13.203.219.206:8000/getsportsdailyactivity');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (var item in data) {
          List<dynamic> images = item['images'];
          List<XFile> imageFiles = images.map<XFile>((img) {
            return XFile(img['image_url']);
          }).toList();
          print(imageFiles);
          print("object---------------------------------------");
        }
      } else {
        print("Error fetching activities: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ LIST, not single

    final List<XFile> images = data['images'];
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
                InkWell(
                  onTap: () {
                    for (var i in images) {
                      debugPrint('IMAGE TYPE: ${i.runtimeType}');
                      debugPrint('IMAGE PATH: ${i.path}');
                    }
                    debugPrint('Images raw data: ${data['images']}');
                    debugPrint('Images length: ${images.length}');
                    for (int i = 0; i < images.length; i++) {
                      debugPrint('Image[$i] path: ${images[i].path}');
                    }
                  },
                  child: Text(
                    "PT Name: ${data['ptName']}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Game Name: ${data['gameName']}",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 8),

                Text(
                  "Description: ${data['activityType']}",
                  style: TextStyle(fontSize: 20),
                ),
                Text("Time: ${data['time']}", style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),
                Text(
                  "Activity Media:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                /// ✅ Use GridView for 3 images per row
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final XFile file = images[index];

                    final bool isRemote = file.path.startsWith('http');

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isRemote
                          ? Image.network(
                              file.path,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loading) {
                                if (loading == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 40),
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

class SportsChatScreen extends StatefulWidget {
  const SportsChatScreen({super.key});

  @override
  _SportsChatScreenState createState() => _SportsChatScreenState();
}

class _SportsChatScreenState extends State<SportsChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      "from": "bot",
      "text": "👋 Welcome to Sports Chat! We’re here to help you out.",
    },
    {"from": "user", "text": "I want to log my training today."},
    {"from": "bot", "text": "What kind of training activity did you do today?"},
  ];

  final List<String> _quickReplies = [
    "2 hrs Football ⚽",
    "3 hrs Cricket 🏏",
    "1 hr Running 🏃",
    "Gym Workout 🏋️",
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String text, {String from = "user"}) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({"from": from, "text": text});
    });

    if (from == "user") {
      Future.delayed(Duration(milliseconds: 600), () {
        setState(() {
          _messages.add({"from": "bot", "text": _defaultBotResponse(text)});
        });
      });
    }
    _controller.clear();
  }

  String _defaultBotResponse(String userText) {
    if (userText.contains("Football")) {
      return "✅ Logged: 2 hrs Football training. Keep it up!";
    } else if (userText.contains("Cricket")) {
      return "✅ Logged: 3 hrs Cricket training. Great session!";
    } else if (userText.contains("Running")) {
      return "✅ Logged: 1 hr Running. Good stamina boost!";
    } else if (userText.contains("Gym")) {
      return "✅ Logged: Gym Workout. Stay strong!";
    } else if (userText.toLowerCase().contains("match")) {
      return "Upcoming matches:\n⚽ Football - Oct 5\n🏏 Cricket - Oct 8";
    } else {
      return "I can help with Training Logs, Player Stats, and Match Info ⚡";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Icon(Icons.arrow_back, color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sports Chat",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "get help 24x7",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          Icon(Icons.translate, color: Colors.black54),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["from"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple[100] : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: isUser
                            ? Radius.circular(16)
                            : Radius.circular(0),
                        bottomRight: isUser
                            ? Radius.circular(0)
                            : Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          spreadRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(msg["text"], style: TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),
          if (_messages.last["from"] == "bot") _buildQuickReplies(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _quickReplies
            .map(
              (reply) => GestureDetector(
                onTap: () => _sendMessage(reply),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: Text(
                    reply,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.menu, color: Colors.grey[700]),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type your query here...",
                border: InputBorder.none,
              ),
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () => _sendMessage(_controller.text),
          ),
          Icon(Icons.mic, color: Colors.grey[700]),
        ],
      ),
    );
  }
}

class ActivityFormSheet extends StatefulWidget {
  final List<String> schools;
  final Function(String, String, Map<String, dynamic>) onSubmit;

  const ActivityFormSheet({
    super.key,
    required this.schools,
    required this.onSubmit,
  });

  @override
  _ActivityFormSheetState createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? activityType, gameName, selectedSchool;
  late String ptName = context.watch<resource>().PresentWorkingUser;

  DateTime? selectedDate;
  String? selectedHour;
  String? selectedAmPm;
  String? selectedDuration;
  bool _isLoading = false;
  // put these inside your State class (e.g. _YourWidgetState)
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _spokenText = "";
  final TextEditingController _descController = TextEditingController();

  // list of many game types (you can expand)
  final List<String> _gameTypes = [
    'Volleyball',
    'Kabaddi',
    'Football',
    'Basketball',
    'Running',
    'Exercise',
    'Warmup',
    'Training',
    'Yoga',
    'Badminton',
    'Hockey',
    'Table Tennis',
    'Athletics',
    'Swimming',
    'Other',
  ];
  final Map<String, String> ptToSchoolMap = {
    'pt1': 'Heal School',
    'pt2': 'Srmc Krishna',
    'pt3': 'Share & Care',
    'pt4': 'Gannavaram',
    'pt5': 'GannavaramG',
    'pt6': 'Kesarapalli',
    'pt7': 'Davajigudem',
    'pt8': 'Golnapalli',
    'pt9': 'MK Baig MC',
    'pt10': 'KBC ZP Boys',
    'pt11': 'CVR HighSchool',
  };

  String? selectedGame; // will bind to the dropdown

  // A convenient helper for setting the default school once
  void _ensureDefaultSchool() {
    selectedSchool = selectedSchool;
  }

  void setSchoolByPtName(String ptName) {
    selectedSchool = ptToSchoolMap[ptName];
  }

  void _startListening() async {
    bool available = await _speech.initialize();

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
            _descController.text = _spokenText;
          });
        },
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // Helper to compute & set duration and also populate selectedHour/selectedAmPm vars
  void _computeDurationAndSetFields() {
    if (_startTime != null && _endTime != null) {
      // compute minutes difference (handles day wrap)
      final int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final int endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      int diff = endMinutes - startMinutes;
      if (diff < 0) diff += 24 * 60; // crossed midnight handling

      final int hours = diff ~/ 60;
      final int minutes = diff % 60;

      // set your selectedDuration in a friendly text format (so existing logic can use it)
      if (hours > 0 && minutes > 0) {
        selectedDuration = '${hours}h ${minutes}m';
      } else if (hours > 0) {
        selectedDuration = '${hours} Hours';
      } else {
        selectedDuration = '${minutes} Minutes';
      }

      // Also set selectedHour & selectedAmPm based on start time
      int hour12 = _startTime!.hour % 12;
      if (hour12 == 0) hour12 = 12;
      selectedHour = hour12.toString();
      selectedAmPm = _startTime!.hour >= 12 ? 'PM' : 'AM';
    }
  }

  List<XFile>? mediaFiles;
  final ImagePicker _picker = ImagePicker();

  void _pickMedia() async {
    final List<XFile> files = await _picker.pickMultiImage();

    setState(() {
      mediaFiles = [
        ...?mediaFiles, // keep previously selected images
        ...files, // add newly selected ones
      ];
    });
  }

  void _submit() async {
    print("entered submit");

    // Validate: require form, date and start/end times (you removed hour/am/pm dropdowns)
    if (!(_formKey.currentState?.validate() == true &&
        selectedDate != null &&
        _startTime != null &&
        _endTime != null)) {
      print(
        "Validation failed: form valid? ${_formKey.currentState?.validate()} "
        "selectedDate:$selectedDate start:$_startTime end:$_endTime",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields (date & times).'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("validated");

      // Save form fields from TextFormFields
      _formKey.currentState!.save();

      // Compute duration & hour/am-pm from start/end times BEFORE building fields
      _computeDurationAndSetFields();

      // Ensure selectedHour/selectedAmPm/selectedDuration are available
      selectedHour ??= (_startTime != null
          ? ((_startTime!.hour % 12 == 0) ? '12' : '${_startTime!.hour % 12}')
          : '0');
      selectedAmPm ??= (_startTime != null
          ? (_startTime!.hour >= 12 ? 'PM' : 'AM')
          : 'AM');
      selectedDuration ??= '0 Minutes';

      final String formattedDate =
          '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}';
      final String formattedTime =
          '${selectedHour!}:00 ${selectedAmPm!} (${selectedDuration!})';

      print("formattedDate: $formattedDate");
      print("formattedTime: $formattedTime");

      var uri = Uri.parse("http://13.203.219.206:8000/postsportsdailyactivity");
      var request = http.MultipartRequest('POST', uri);

      // pick correct game_name: prefer selectedGame (dropdown) else fallback to gameName text field
      final String gameValue = selectedGame ?? gameName ?? '';

      request.fields['pt_name'] = ptName ?? '';
      request.fields['activity_type'] = activityType ?? '';
      request.fields['game_name'] = gameValue;
      request.fields['date'] = formattedDate;
      request.fields['time'] = formattedTime;
      request.fields['school'] = selectedSchool ?? '';

      // Add files under the repeated key 'files' (Django getlist('files'))
      if (mediaFiles != null && mediaFiles!.isNotEmpty) {
        print("Attaching ${mediaFiles!.length} files...");
        for (int i = 0; i < mediaFiles!.length; i++) {
          final file = mediaFiles![i];
          // fromPath is simpler and handles content-type automatically on mobile
          final multipartFile = await http.MultipartFile.fromPath(
            'images', // repeated key — backend should accept getlist('files')
            file.path,
            filename: file.name,
          );
          request.files.add(multipartFile);
        }
      }

      print("Request fields: ${request.fields}");
      print("Request files: ${request.files.map((f) => f.filename).toList()}");

      final streamedResp = await request.send();

      // Read response body
      final respBody = await streamedResp.stream.bytesToString();
      setState(() => _isLoading = false);

      print("Response status: ${streamedResp.statusCode}");
      print("Response body: $respBody");

      if (streamedResp.statusCode == 200 || streamedResp.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ Activity submitted')));

        // Notifications flow (unchanged)
        try {
          final tokenResponse = await http.get(
            Uri.parse("http://13.203.219.206:8000/getsportsnotificationtoken/"),
          );

          if (tokenResponse.statusCode == 200) {
            final data = jsonDecode(tokenResponse.body);
            final List<dynamic> tokens = data['tokens'] ?? [];

            await http.post(
              Uri.parse("http://13.203.219.206:8000/sendnotificationtoall/"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "title": "New PT Activity!",
                "body": "New activity posted by $ptName",
              }),
            );

            print("🔔 Notifications sent to ${tokens.length} devices.");
          } else {
            print("⚠️ Failed to fetch tokens: ${tokenResponse.body}");
          }
        } catch (e) {
          print("⚠️ Notification error: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Activity submitted & notifications sent!')),
        );

        Navigator.pop(context);
      } else {
        print("❌ Submission error: $respBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to submit activity: ${streamedResp.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Exception while submitting: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error occurred while submitting. $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    setSchoolByPtName(ptName);

    // auto-select today
  }

  List<File> selectedFiles = [];

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text("Local Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia();
                },
              ),
              ListTile(
                leading: Icon(Icons.folder_special, color: Colors.green),
                title: Text("App Gallery (GPS Camera)"),
                onTap: () async {
                  Navigator.pop(context);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppGallerySelectionScreen(),
                    ),
                  );

                  if (result != null && result is List<File>) {
                    setState(() {
                      mediaFiles = [
                        ...?mediaFiles,
                        ...result.map((f) => XFile(f.path)),
                      ];
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
    // ensure default school is set for initial UI

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
                // small grab bar
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

                // Title
                Text(
                  "Add Activity",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // NEW: Start Time & End Time row (two buttons side-by-side)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _startTime = picked;
                              // when start chosen, also compute fields if end exists
                              _computeDurationAndSetFields();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('Start Time', style: TextStyle(fontSize: 12)),
                            SizedBox(height: 6),
                            Text(
                              _startTime == null
                                  ? '-- : --'
                                  : _startTime!.format(context),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _endTime = picked;
                              // compute duration & populate selectedHour/AMPM/duration
                              _computeDurationAndSetFields();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('End Time', style: TextStyle(fontSize: 12)),
                            SizedBox(height: 6),
                            Text(
                              _endTime == null
                                  ? '-- : --'
                                  : _endTime!.format(context),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Select School - default set to 'Heal School' (editable)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDecoration(selectedSchool!),
                        value: selectedSchool,
                        validator: (v) => v == null ? 'Required' : null,
                        menuMaxHeight: 200,
                        items: [],
                        onChanged: (String? value) {},
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // PT Name with default 'ptname1' but editable; using initialValue so existing onSaved works
                TextFormField(
                  initialValue: context.watch<resource>().PresentWorkingUser,
                  decoration: _inputDecoration('PT Name'),
                  onSaved: (v) => ptName = v!,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

                SizedBox(height: 12),

                // Activity Type (unchanged UI but keep as text input)
                //SizedBox(height: 12),

                // Game Type dropdown (scrollable list that shows up to 5 items in the popup)
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: Colors.white),
                  child: DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Game Type'),
                    value: selectedGame,
                    onChanged: (v) => setState(() => selectedGame = v),
                    items: _gameTypes
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    validator: (v) => v == null ? 'Required' : null,
                    // show max 5 items by limiting menu height (approx item height 48 * 5)
                    menuMaxHeight: 48 * 5,
                  ),
                ),
                SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  decoration: _inputDecoration('Description...').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        await Permission.microphone.request();

                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                    ),
                  ),
                  onSaved: (v) => activityType = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                // Date picker (unchanged)
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2026),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        icon: Icon(Icons.calendar_today),
                        label: Text(
                          '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                        ),
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

                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
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

                // Show selected images thumbnails (display under the Select Images button, above submit)
                if (mediaFiles != null && mediaFiles!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  // horizontal scroller for thumbnails
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mediaFiles!.length,
                      itemBuilder: (context, i) {
                        final file = mediaFiles![i];
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: FileImage(
                                File(file.path),
                              ), // convert XFile to File for FileImage
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                SizedBox(height: 20),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class AdminDashboard extends StatefulWidget {
  final String username;

  const AdminDashboard({super.key, required this.username});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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

  int totalPTs = 11; // example count
  int totalBills = 25; // example count
  int totalSportsAdmins = 5; // example count

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Admin Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Schools"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("PTs"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text("Bills"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text("Sports Admin"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text("Announcements"),
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.notifications),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.account_circle),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Profile Bar ----------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage(
                        "assets/imgicon1.png",
                      ), // replace with your admin image
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Mr. Admin Name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- 2x2 Dashboard Cards ----------
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildDashboardCard("Schools", schools.length, Icons.school),
                _buildDashboardCard("PTs", totalPTs, Icons.person),
                _buildDashboardCard("Bills", totalBills, Icons.receipt_long),
                _buildDashboardCard(
                  "Sports Admin",
                  totalSportsAdmins,
                  Icons.sports_soccer,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------- Schools Table ----------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Schools List",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Column(
                      children: schools
                          .map(
                            (school) => ListTile(
                              leading: const Icon(Icons.school),
                              title: Text(school),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SchoolsHomePage(
                                      username: widget.username,
                                    ),
                                  ),
                                );
                                // Navigate to school details page
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- Announcements ----------
            Card(
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Announcements",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.campaign),
                      title: Text("Sports event on Oct 10th"),
                    ),
                    ListTile(
                      leading: Icon(Icons.campaign),
                      title: Text("Fee due reminder for PTs"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, int count, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 7),
            Text(
              "$count",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    final dir = await getApplicationDocumentsDirectory();

    final files = Directory("${dir.path}/gps_photos")
        .listSync()
        .where(
          (item) =>
              item.path.endsWith(".png") ||
              item.path.endsWith(".jpg") ||
              item.path.endsWith(".mp4"),
        )
        .map((item) => File(item.path))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() => images = files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Saved Photos.."),
        backgroundColor: Colors.white,
      ),

      body: images.isEmpty
          ? const Center(
              child: Text(
                "📂 No images saved yet",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => images[index].path.endsWith(".mp4")
                            ? VideoPlayerScreen(file: images[index])
                            : FullImageScreen(
                                image: images[index],
                                onDelete: () {
                                  File(images[index].path).deleteSync();
                                  setState(() => images.removeAt(index));
                                },
                              ),
                      ),
                    );

                    // If video was deleted, refresh UI
                    if (result == true) {
                      setState(() => images.removeAt(index));
                    }
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // 🖼 Show thumbnail if image, video icon if video
                        images[index].path.endsWith(".mp4")
                            ? Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Image.file(
                                images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),

                        if (images[index].path.endsWith(".mp4"))
                          const Positioned(
                            right: 6,
                            bottom: 6,
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController videoController;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        videoController.play();
      });
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  Future<void> _deleteVideo(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Video?"),
        content: const Text("Are you sure you want to delete this video?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.file.delete();
        Navigator.pop(context, true); // send success delete back
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error deleting video")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 30, color: Colors.redAccent),
            onPressed: () => _deleteVideo(context),
          ),
        ],
      ),
      body: Center(
        child: videoController.value.isInitialized
            ? AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  const FullImageScreen({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Photo?"),
                  content: const Text(
                    "Are you sure you want to delete this photo permanently?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                onDelete();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      // 🖼️ Full Interactive Image View
      body: Center(
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: FittedBox(fit: BoxFit.contain, child: Image.file(image)),
          ),
        ),
      ),
    );
  }
}

class AppGallerySelectionScreen extends StatefulWidget {
  const AppGallerySelectionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AppGallerySelectionScreenState createState() =>
      _AppGallerySelectionScreenState();
}

class _AppGallerySelectionScreenState extends State<AppGallerySelectionScreen> {
  List<File> allFiles = [];
  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/gps_photos");

    if (!folder.existsSync()) return;

    final files = folder
        .listSync()
        .where(
          (item) =>
              item.path.endsWith(".png") ||
              item.path.endsWith(".jpg") ||
              item.path.endsWith(".mp4"),
        )
        .map((item) => File(item.path))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() => allFiles = files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Images"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedFiles);
            },
            child: Text(
              "DONE",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: allFiles.isEmpty
          ? Center(child: Text("No images found"))
          : GridView.builder(
              padding: EdgeInsets.all(15),
              itemCount: allFiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10, // ADD THIS
                mainAxisSpacing: 10, // ADD THIS
              ),
              itemBuilder: (context, index) {
                final file = allFiles[index];
                final isVideo = file.path.endsWith(".mp4");
                final isSelected = selectedFiles.contains(file);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? selectedFiles.remove(file)
                          : selectedFiles.add(file);
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: !isVideo
                              ? DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: isVideo ? Colors.black45 : null,
                        ),
                        child: isVideo
                            ? Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected
                              ? Colors.blue
                              : Colors.white,
                          child: Icon(
                            isSelected ? Icons.check : Icons.circle_outlined,
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class MyActivitiesPage extends StatelessWidget {
  const MyActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("My Activities")));
}

class SavedSchemesPage extends StatelessWidget {
  const SavedSchemesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Saved Schemes")));
}

class ApplicationHistoryPage extends StatelessWidget {
  const ApplicationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Application History")));
}

class SupportHelpdeskPage extends StatelessWidget {
  const SupportHelpdeskPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Support & Helpdesk")));
}

class LanguagePreferencePage extends StatelessWidget {
  const LanguagePreferencePage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Language Preferences")));
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                // Close the success dialog
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  // ---------------- CONTACT ACTIONS ----------------
  void _openEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'dev@chandus7.in',
      query: 'subject=Regarding Your App',
    );
    launchUrl(uri);
  }

  void _openWebsite() async {
    final Uri uri = Uri.parse('https://chandus7.in');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openLinkedIn() async {
    final Uri uri = Uri.parse('https://linkedin.chandus7.in');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

              child: Column(
                children: [
                  // -------------------------------------------------------
                  // HEADER
                  // -------------------------------------------------------
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D92FF), Color(0xFF05A64C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      "About Application",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // -------------------------------------------------------
                  // APP SUMMARY CARD
                  // -------------------------------------------------------
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title("Application Summary"),
                        const SizedBox(height: 14),

                        _infoRow(
                          icon: Icons.info_outline,
                          color: Colors.blue,
                          text:
                              "This application helps manage school sports activities, PT sessions, daily logs, "
                              "and stores GPS-tagged images with an easy interface for teachers and students.",
                        ),

                        const SizedBox(height: 14),
                        _simpleRow(
                          Icons.update,
                          Colors.green,
                          "Version: 1.0.0",
                        ),

                        const SizedBox(height: 6),
                        _simpleRow(
                          Icons.calendar_today,
                          Colors.orange,
                          "Last Updated: Feb 2025",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // -------------------------------------------------------
                  // DEVELOPER CARD
                  // -------------------------------------------------------
                  _buildCard(
                    gradient: [Colors.blue.shade50, Colors.green.shade50],
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              "assets/profile.jpg",
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        _title("Developed By", size: 15),

                        const SizedBox(height: 4),
                        const Text(
                          "S Chandra Sekhar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),
                        const Text(
                          "Software Developer • Freelancer",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // -------------------------------------------------------
                  // CONTACT SECTION
                  // -------------------------------------------------------
                  _title("Reach Me Out at", size: 17),

                  const SizedBox(height: 7),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _contactIcon(
                        Icons.email_rounded,
                        "Email",
                        Colors.redAccent,
                        _openEmail,
                      ),
                      const SizedBox(width: 22),
                      _contactIcon(
                        Icons.language_rounded,
                        "Website",
                        Colors.blueAccent,
                        _openWebsite,
                      ),
                      const SizedBox(width: 22),
                      _contactIcon(
                        Icons.link,
                        "LinkedIn",
                        Colors.blue,
                        _openLinkedIn,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // -------------------------------------------------------
                  // FOOTER
                  // -------------------------------------------------------
                  Column(
                    children: const [
                      Divider(thickness: 1, color: Colors.black12),
                      SizedBox(height: 2),
                      Text(
                        "© 2025 Sports For Change",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // REUSABLE UI COMPONENTS
  // -------------------------------------------------------

  Widget _buildCard({required Widget child, List<Color>? gradient}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _title(String text, {double size = 18}) {
    return Text(
      text,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }

  Widget _simpleRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// ---------------- CONTACT ICON ----------------
Widget _contactIcon(
  IconData icon,
  String label,
  Color color,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: color.withOpacity(0.17),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
