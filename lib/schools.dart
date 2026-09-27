// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use, unnecessary_import

import 'dart:io';
import 'gpscamera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';
import 'main.dart';
import 'resource.dart';
import 'loginsignup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

class UserSession {
  static const _keyUsername = "defaultuserrr";

  // ---------- SAVE ----------

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username); // ✅ FIXED
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // ---------- LOGOUT ----------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

const List<String> kSchools = [
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

const Map<String, String> kPtToSchool = {
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

class SchoolsHomePage extends StatefulWidget {
  final String username;

  const SchoolsHomePage({super.key, required this.username});
  @override
  _SchoolsHomePageState createState() => _SchoolsHomePageState();
}

class _SchoolsHomePageState extends State<SchoolsHomePage> {
  final List<String> schools = kSchools;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, Map<String, Map<String, dynamic>>> activities = {};
  int _currentIndex = 0;

  String presentUser = '';
  String userRole = 'Default';

  bool _showForm = false;
  String _selectedGender = 'Male';
  final TextEditingController _reportSearchController = TextEditingController();
  late String _reportSelectedSchool;
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

  void addActivity(String school, String day, Map<String, dynamic> data) {
    setState(() {
      activities.putIfAbsent(school, () => {});
      activities[school]!.putIfAbsent(day, () => data);
    });
  }

  void fetchActivitiesFromBackend() async {
    activities.clear();
    final url = Uri.parse('https://api.chandus7.in/getsportsdailyactivity');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (var item in data) {
          String school = item['school'];
          String rawDate = item['date'];
          String date = rawDate;

          try {
            List<String> parts = rawDate.split('/');
            if (parts.length == 3) {
              int month = int.parse(parts[0]);
              int day = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              date = "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
            }
          } catch (_) {}

          final String time = item['time'];
          final String ptName = item['pt_name'];
          final String activityType = item['activity_type'];
          final String gameName = item['game_name'];

          final List<dynamic> images = item['images'];
          final List<XFile> imageFiles = images.map<XFile>((img) => XFile(img['image_url'])).toList();

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

        _flattenData();
        _filterDataInternal();
        setState(() {});
      } else {
        debugPrint("Error fetching activities: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception fetching activities: $e");
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
    presentUser = widget.username;
    _reportSelectedSchool = schools[0];
    _initUserRole();
    fetchActivitiesFromBackend();
    requestNotificationPermission();
  }

  @override
  void dispose() {
    _reportSearchController.dispose();
    super.dispose();
  }

  void _initUserRole() {
    if (kPtToSchool.containsKey(widget.username)) {
      userRole = 'Pt Sir';
    } else if (widget.username == 'admin' || widget.username == 'official') {
      userRole = 'Administrator';
    } else if (widget.username == 'test' || widget.username == 'tester') {
      userRole = 'Testing';
    } else {
      userRole = 'Default';
    }
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
                      Navigator.pop(context);
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
                          builder: (context) => SportsChatScreen(),
                        ),
                      );
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
                          builder: (context) => SettingsPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                      );
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
                  await prefs.clear();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
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

        final bool isAdmin = widget.username == 'admin' || widget.username == 'official';
        final String? assignedSchool = kPtToSchool[widget.username];
        final bool isClickable = isAdmin || assignedSchool == school;

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

  Widget _buildReportSection() {
    final List<Map<String, String>> schoolActivities = allData
        .where((item) => item['School'] == _reportSelectedSchool)
        .where((item) {
          final query = _reportSearchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return (item['PT Name'] ?? '').toLowerCase().contains(query) ||
              (item['Game'] ?? '').toLowerCase().contains(query) ||
              (item['Date'] ?? '').contains(query);
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          if (!_showForm)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: TextField(
                    controller: _reportSearchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by PT name, game, or date...',
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _reportSelectedSchool,
                    onChanged: (value) => setState(() => _reportSelectedSchool = value!),
                    decoration: InputDecoration(
                      labelText: 'Select School',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: schools.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    menuMaxHeight: 250,
                  ),
                ),

                const SizedBox(height: 8),

                if (schoolActivities.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No activities found for this school.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      itemCount: schoolActivities.length,
                      itemBuilder: (context, index) {
                        final item = schoolActivities[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(Icons.sports, color: Colors.orange),
                            ),
                            title: Text(item['PT Name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['Game']} • ${item['Date']} • ${item['Time']}'),
                            trailing: const Icon(Icons.chevron_right),
                          ),
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
    allData.clear();
    activities.forEach((school, dateMap) {
      dateMap.forEach((dateKey, details) {
        final cleanDate = dateKey.contains('_') ? dateKey.split('_').first : dateKey;
        allData.add({
          'School': school,
          'Date': cleanDate,
          'PT Name': details['ptName'] ?? '',
          'Activity': details['activityType'] ?? '',
          'Game': details['gameName'] ?? '',
          'Time': details['time'] ?? '',
        });
        activityDates.add(dateKey);
      });
    });
  }

  void _filterDataInternal() {
    final selectedFormat = DateFormat('dd-MM-yyyy');
    final selectedMonth = selectedDate.month;
    final selectedYear = selectedDate.year;

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
  }

  void _filterData() {
    _filterDataInternal();
    setState(() {});
  }

  Future<void> _exportToExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Activities';

    final headers = ['School', 'Date', 'PT Name', 'Activity', 'Game', 'Time'];
    final colWidths = [20.0, 14.0, 14.0, 40.0, 16.0, 12.0];

    // Header row styling
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#1565C0';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.fontSize = 11;
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      sheet.getRangeByIndex(1, i + 1).columnWidth = colWidths[i];
    }

    // Data rows
    for (int i = 0; i < filteredData.length; i++) {
      final row = filteredData[i];
      for (int j = 0; j < headers.length; j++) {
        final cell = sheet.getRangeByIndex(i + 2, j + 1);
        cell.setText(row[headers[j]] ?? '');
        cell.cellStyle.backColor = i.isEven ? '#E3F2FD' : '#FFFFFF';
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        cell.cellStyle.fontSize = 10;
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
    final rows = filteredData.map((row) => headers.map((h) => row[h] ?? '—').toList()).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SportsForChange — Activity Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.0),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(3.2),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: headers
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              ...rows.asMap().entries.map(
                (entry) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: entry.key.isEven ? PdfColors.blue50 : PdfColors.white,
                  ),
                  children: entry.value
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Total records: ${rows.length}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
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
    school = kPtToSchool[widget.username];

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

    _rebuildPages();

    // Fetch data from backend BEFORE setting ready state
    fetchActivitiesFromBackend();

    // Finally update screen
    setState(() {
      _isScreenReady = true;
    });
  }

  void fetchActivitiesFromBackend() async {
    activities.clear();
    final url = Uri.parse(
      'https://api.chandus7.in/getsportsdailyactivity?pt_name=${widget.username}',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (var item in data) {
          String itemSchool = item['school'];
          String rawDate = item['date'];
          String date = rawDate;

          try {
            List<String> parts = rawDate.split('/');
            if (parts.length == 3) {
              int month = int.parse(parts[0]);
              int day = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              date = "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
            }
          } catch (_) {}

          final String time = item['time'];
          final String ptName = item['pt_name'];
          final String activityType = item['activity_type'];
          final String gameName = item['game_name'];

          final List<dynamic> images = item['images'];
          final List<XFile> imageFiles = images.map<XFile>((img) => XFile(img['image_url'])).toList();

          activities.putIfAbsent(itemSchool, () => {});
          String finalKey = date;
          int count = 1;
          while (activities[itemSchool]!.containsKey(finalKey)) {
            count++;
            finalKey = '${date}_$count';
          }

          activities[itemSchool]![finalKey] = {
            'ptName': ptName,
            'activityType': activityType,
            'gameName': gameName,
            'time': time,
            'images': imageFiles,
          };
        }

        _flattenData();
        _filterDataInternal();
        if (mounted) setState(() => _rebuildPages());
      } else {
        debugPrint("Error fetching activities: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception fetching activities: $e");
    }
  }

  void _rebuildPages() {
    _pages = [
      buildHomeContent(),
      CameraScreen(cameras: cameras),
      buildRecordsContent(),
      buildHomeContent3(),
    ];
  }

  final List<String> schools = kSchools;

  void _flattenData() {
    allData.clear();
    activities.forEach((school, dateMap) {
      dateMap.forEach((dateKey, details) {
        final cleanDate = dateKey.contains('_') ? dateKey.split('_').first : dateKey;
        allData.add({
          'School': school,
          'Date': cleanDate,
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

  void _filterDataInternal() {
    final selectedFormat = DateFormat('dd-MM-yyyy');
    final selectedMonth = selectedDate.month;
    final selectedYear = selectedDate.year;

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
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchoolDetailsPage(
              schoolName: school!,
              activities: activities[school] ?? {},
            ),
          ),
        );
        break;
      case 1:
        _showSupportHelpdesk();
        break;
      case 2:
        _showLanguagePreference();
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => AboutAppPage()));
        break;
    }
  }

  void _showSupportHelpdesk() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.support_agent_rounded, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 12),
            const Text('Support & Helpdesk'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Reach us at:', style: TextStyle(color: Colors.black54, fontSize: 13)),
            SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email, color: Color(0xFF1565C0)),
              title: Text('support@sportsforchange.in'),
              subtitle: Text('Email Support'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone, color: Colors.green),
              title: Text('+91 98765 43210'),
              subtitle: Text('WhatsApp / Call'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: Colors.orange),
              title: Text('Mon–Sat, 9 AM – 6 PM'),
              subtitle: Text('Support Hours'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePreference() {
    String selected = 'English';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language_rounded, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Text('Language Preference'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Telugu', 'Hindi']
                .map(
                  (lang) => RadioListTile<String>(
                    value: lang,
                    groupValue: selected,
                    title: Text(lang),
                    activeColor: const Color(0xFF1565C0),
                    onChanged: (v) => setS(() => selected = v!),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndexParticularPtPage = 0;
  List<Widget> _pages = [];

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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                      );
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
            icon: const Icon(Icons.more_vert),
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
                  await prefs.clear();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                } else if (value == 3) {
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
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) =>
            setState(() => _selectedIndexParticularPtPage = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_outlined), activeIcon: Icon(Icons.sports), label: "Activities"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: "Records"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: _pages[_selectedIndexParticularPtPage],

      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          builder: (_) => ActivityFormSheet(
            schools: schools,
            onSubmit: addActivity,
            onSuccess: fetchActivitiesFromBackend,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget buildHomeContent() {
    final now = DateTime.now();
    final todayKey =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    final myActivities = allData
        .where((a) => a['PT Name'] == widget.username)
        .toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('dd-MM-yyyy').parse(a['Date']!);
          final db = DateFormat('dd-MM-yyyy').parse(b['Date']!);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

    final submittedToday = myActivities.any((a) => (a['Date'] ?? '') == todayKey);

    int thisMonthCount = 0;
    for (final a in myActivities) {
      try {
        final parts = (a['Date'] ?? '').split('-');
        if (parts.length >= 3 &&
            int.parse(parts[1]) == now.month &&
            int.parse(parts[2]) == now.year) {
          thisMonthCount++;
        }
      } catch (_) {}
    }

    final recent = myActivities.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ──────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FutureBuilder<String?>(
                      future: fetchUserProfileImageUrl(widget.username),
                      builder: (context, snap) => CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        backgroundImage: snap.hasData
                            ? NetworkImage(snap.data!) as ImageProvider
                            : const AssetImage('assets/imgicon1.png'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            school ?? '—',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14),
                          ),
                          Text(
                            DateFormat('EEE, d MMM yyyy').format(now),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: submittedToday
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.orange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: submittedToday
                          ? Colors.greenAccent.withValues(alpha: 0.7)
                          : Colors.orangeAccent.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        submittedToday
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        submittedToday
                            ? "Activity submitted today ✓"
                            : "No activity submitted today",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats row ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _ptStatCard("This Month", thisMonthCount,
                    Icons.calendar_month, const Color(0xFF1565C0)),
                const SizedBox(width: 10),
                _ptStatCard("Total", myActivities.length,
                    Icons.bar_chart, const Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                _ptStatCard("School", 1,
                    Icons.school, const Color(0xFFAD1457)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick actions ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ptQuickAction(
                    "Calendar",
                    Icons.calendar_today_outlined,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF1565C0),
                    () {
                      if (school != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolDetailsPage(
                              schoolName: school!,
                              activities: activities[school] ?? {},
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ptQuickAction(
                    "Records",
                    Icons.list_alt_outlined,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF2E7D32),
                    () => setState(
                        () => _selectedIndexParticularPtPage = 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ptQuickAction(
                    "Gallery",
                    Icons.photo_library_outlined,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFE65100),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GalleryScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Recent submissions ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Submissions",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                if (school != null)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchoolDetailsPage(
                          schoolName: school!,
                          activities: activities[school] ?? {},
                        ),
                      ),
                    ),
                    child: const Text("See all"),
                  ),
              ],
            ),
          ),

          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.sports_handball,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      "No activities yet.\nTap + to submit your first activity!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              itemCount: recent.length,
              itemBuilder: (context, i) {
                final act = recent[i];
                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: const Icon(Icons.sports,
                          color: Color(0xFF1565C0), size: 20),
                    ),
                    title: Text(
                      act['Game'] ?? act['Activity'] ?? 'Activity',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      act['Date'] ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _ptStatCard(
      String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ptQuickAction(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomeContent3() {
    final List<Map<String, dynamic>> options = [
      {"title": "My Activities", "icon": Icons.task_alt_rounded, "color": const Color(0xFF1565C0), "subtitle": "View school activities"},
      {"title": "Support & Helpdesk", "icon": Icons.support_agent_rounded, "color": Colors.teal, "subtitle": "Contact support team"},
      {"title": "Language Preference", "icon": Icons.language_rounded, "color": Colors.purple, "subtitle": "Change app language"},
      {"title": "Settings", "icon": Icons.settings_outlined, "color": Colors.orange, "subtitle": "App preferences"},
      {"title": "About App", "icon": Icons.info_outline, "color": Colors.grey, "subtitle": "Version & developer info"},
    ];

    return Column(
      children: [
        // -------- HEADER GRADIENT SECTION --------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              FutureBuilder<String?>(
                future: fetchUserProfileImageUrl(widget.username),
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      backgroundImage: snapshot.hasData
                          ? NetworkImage(snapshot.data!) as ImageProvider
                          : const AssetImage('assets/imgicon1.png'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Text(
                "Welcome back,",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.username.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  school ?? 'Physical Trainer',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // -------- OPTIONS LIST --------
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
            itemBuilder: (context, index) {
              final item = options[index];
              final color = item["color"] as Color;
              return InkWell(
                onTap: () => _handleOptionTap(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item["icon"] as IconData, size: 22, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item["subtitle"] as String,
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey.shade400),
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

  Widget buildRecordsContent() {
    final myActivities = allData
        .where((a) => a['PT Name'] == widget.username)
        .toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('dd-MM-yyyy').parse(a['Date']!);
          final db = DateFormat('dd-MM-yyyy').parse(b['Date']!);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

    return Container(
      color: const Color(0xFFF3F6FB),
      child: myActivities.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No records yet',
                    style: TextStyle(color: Colors.grey, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Submit your first activity using the + button',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'My Submissions',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${myActivities.length} total',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: myActivities.length,
                    itemBuilder: (context, index) {
                      final item = myActivities[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.sports, color: Color(0xFF1565C0), size: 22),
                          ),
                          title: Text(
                            item['Game'] ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                item['Activity'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['Date']} • ${item['Time']}',
                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _prepareEvents();
  }

  void _prepareEvents() {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    widget.activities.forEach((dateKey, data) {
      try {
        final cleanDate = dateKey.contains('_') ? dateKey.split('_').first : dateKey;
        final parts = cleanDate.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final date = DateTime(year, month, day);
          events[date] = events[date] ?? [];
          events[date]!.add(data);
        }
      } catch (_) {}
    });
    setState(() => _events = events);
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedActivities = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.schoolName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${widget.activities.length} activities total', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 1,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A237E),
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF1565C0)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          if (_selectedDay != null)
            Container(
              color: const Color(0xFFE8F0FE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 15, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(_selectedDay!),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedActivities.isEmpty ? Colors.grey : const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedActivities.isEmpty
                          ? 'No activities'
                          : '${selectedActivities.length} ${selectedActivities.length == 1 ? "activity" : "activities"}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Tap a date to view activities', style: TextStyle(color: Colors.grey, fontSize: 15)),
                        SizedBox(height: 6),
                        Text('Blue dot = activities recorded', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : selectedActivities.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_handball, size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No activities on this date', style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedActivities.length,
                        itemBuilder: (context, index) {
                          final act = selectedActivities[index];
                          final selectedDateStr = DateFormat('dd-MM-yyyy').format(_selectedDay!);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailsPage(
                                    schoolName: widget.schoolName,
                                    date: selectedDateStr,
                                    data: act,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.sports, color: Color(0xFF1565C0), size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            act['gameName'] ?? '---',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${act['ptName'] ?? ""} • ${act['time'] ?? ""}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1565C0)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final List<XFile> images = (data['images'] as List<dynamic>?)?.cast<XFile>() ?? [];
    final gameName = data['gameName'] ?? '—';
    final ptName = data['ptName'] ?? '—';
    final activityType = data['activityType'] ?? '—';
    final time = data['time'] ?? '—';

    Widget infoRow(IconData icon, String label, String value, Color color) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(
                gameName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.sports_handball, size: 70, color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1565C0)),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          infoRow(Icons.person_outline, 'PT Name', ptName, const Color(0xFF1565C0)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          infoRow(Icons.sports_handball, 'Game', gameName, Colors.orange),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          infoRow(Icons.description_outlined, 'Activity Description', activityType, Colors.green),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          infoRow(Icons.access_time, 'Time', time, Colors.purple),
                          if (images.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1),
                            ),
                            infoRow(Icons.photo_library_outlined, 'Media', '${images.length} photo(s)', Colors.teal),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Activity Photos',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: images.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final XFile file = images[index];
                        final bool isRemote = file.path.startsWith('http');
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                body: Center(
                                  child: isRemote
                                      ? Image.network(file.path)
                                      : Image.file(File(file.path)),
                                ),
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isRemote
                                ? Image.network(
                                    file.path,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, loading) =>
                                        loading == null
                                            ? child
                                            : Container(
                                                color: const Color(0xFFE3F2FD),
                                                child: const Center(child: CircularProgressIndicator()),
                                              ),
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFEEEEEE),
                                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                    ),
                                  )
                                : Image.file(
                                    File(file.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 40),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
  final VoidCallback? onSuccess;

  const ActivityFormSheet({
    super.key,
    required this.schools,
    required this.onSubmit,
    this.onSuccess,
  });

  @override
  _ActivityFormSheetState createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? activityType, gameName, selectedSchool;
  String ptName = "School not selected";
  String ptName2 = "School not selected";
  int _participantsCount = 0;
  final TextEditingController _participantsController =
      TextEditingController(text: '0');
  final TextEditingController _ptNameController = TextEditingController();

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
    'Multiple',
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
  final Map<String, String> ptToSchoolMap = kPtToSchool;

  String? selectedGame; // will bind to the dropdown

  void setSchoolByPtName(String ptName) {
    setState(() {
      selectedSchool = ptToSchoolMap[ptName];
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final username = await UserSession.getUsername();

    setState(() {
      ptName2 = username ?? "School Not Selected..";
      _ptNameController.text = ptName2;
    });

    setSchoolByPtName(ptName2);
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
    if (selectedSchool == null || selectedSchool!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School not detected. Please re-open this form.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() == true &&
        selectedDate != null &&
        _startTime != null &&
        _endTime != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (date & times).')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      final uri = Uri.parse("https://api.chandus7.in/postsportsdailyactivity");
      final request = http.MultipartRequest('POST', uri);

      final String gameValue = selectedGame ?? gameName ?? '';

      request.fields['pt_name'] = ptName2;
      request.fields['activity_type'] = activityType ?? '';
      request.fields['game_name'] = gameValue;
      request.fields['date'] = formattedDate;
      request.fields['time'] = formattedTime;
      request.fields['school'] = selectedSchool ?? '';
      request.fields['participants_count'] = _participantsCount.toString();

      if (mediaFiles != null && mediaFiles!.isNotEmpty) {
        for (final file in mediaFiles!) {
          request.files.add(await http.MultipartFile.fromPath('images', file.path, filename: file.name));
        }
      }

      final streamedResp = await request.send();
      final respBody = await streamedResp.stream.bytesToString();
      setState(() => _isLoading = false);

      if (streamedResp.statusCode == 200 || streamedResp.statusCode == 201) {
        try {
          await http.post(
            Uri.parse("https://api.chandus7.in/sendnotificationtoall/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"title": "New PT Activity!", "body": "New activity posted by $ptName2"}),
          );
        } catch (e) {
          debugPrint("Notification error: $e");
        }

        if (!context.mounted) return;
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        debugPrint("Submission error ${ streamedResp.statusCode}: $respBody");
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit activity (${streamedResp.statusCode}).')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Exception while submitting: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while submitting: $e')),
      );
    }
  }

  @override
  void dispose() {
    _participantsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        selectedSchool ?? 'Detecting school...',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // PT Name with default 'ptname1' but editable; using initialValue so existing onSaved works
                TextFormField(
                  controller: _ptNameController,
                  decoration: _inputDecoration('PT Name'),
                  onSaved: (v) => ptName2 = v!,
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

                // Participants count
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _participantsController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('No. of Participants'),
                        onSaved: (v) =>
                            _participantsCount = int.tryParse(v ?? '0') ?? 0,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Enter a valid count';
                          return null;
                        },
                      ),
                    ),
                  ],
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
  final List<String> schools = kSchools;
  final int totalPTs = 11;
  int totalActivities = 0;
  int _todayCount = 0;
  Map<String, int> _perSchoolCounts = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('https://api.chandus7.in/getsportsdailyactivity'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final counts = <String, int>{};
        final now = DateTime.now();
        final todayStr = '${now.month}/${now.day}/${now.year}';
        int todayC = 0;
        for (final item in data) {
          final school = (item['school'] as String?) ?? '';
          counts[school] = (counts[school] ?? 0) + 1;
          if ((item['date'] as String?) == todayStr) todayC++;
        }
        if (mounted) {
          setState(() {
            totalActivities = data.length;
            _perSchoolCounts = counts;
            _todayCount = todayC;
            _loadingStats = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingStats = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Consumer<resource>(
        builder: (context, resource, child) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.69,
            child: Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(widget.username),
                    accountEmail: const Text("Administrator"),

                    currentAccountPicture: FutureBuilder<String?>(
                      future: Future.value(null),
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
                      Navigator.pop(context);
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ──────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "SportsForChange",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Administrator Dashboard",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _adminStatTile(
                        _loadingStats ? '—' : '$totalActivities',
                        "Total",
                        Icons.sports,
                      ),
                      const SizedBox(width: 8),
                      _adminStatTile(
                        _loadingStats ? '—' : '$_todayCount',
                        "Today",
                        Icons.today,
                      ),
                      const SizedBox(width: 8),
                      _adminStatTile('${schools.length}', "Schools", Icons.school),
                      const SizedBox(width: 8),
                      _adminStatTile('$totalPTs', "PTs", Icons.people),
                    ],
                  ),
                ],
              ),
            ),

            // ── Quick actions ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  _adminQuickAction(
                    "All Records",
                    Icons.list_alt_outlined,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF1565C0),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchoolsHomePage(username: widget.username),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _adminQuickAction(
                    "Send Notification",
                    Icons.notifications_outlined,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFE65100),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SportsChatScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _adminQuickAction(
                    "Settings",
                    Icons.settings_outlined,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF2E7D32),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    ),
                  ),
                ],
              ),
            ),

            // ── Schools overview ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Text(
                    "Schools Activity Overview",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_loadingStats)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: schools.map((school) {
                  final count = _perSchoolCounts[school] ?? 0;
                  final maxC = totalActivities > 0 ? totalActivities : 1;
                  final progress = (count / maxC).clamp(0.0, 1.0);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchoolsHomePage(username: widget.username),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school_outlined,
                                  size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  school,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '$count ${count == 1 ? 'activity' : 'activities'}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1565C0)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _adminStatTile(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminQuickAction(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
    final folder = Directory("${dir.path}/gps_photos");

    if (!folder.existsSync()) {
      setState(() => images = []);
      return;
    }

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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
            child: Text(text3),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
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
