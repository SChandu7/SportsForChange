import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SportsEventApp());
}

class SportsEventApp extends StatelessWidget {
  const SportsEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sports Event Management',
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StudentInterface()),
                    );
                  },
                  child: const Text('Student Interface',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const SelectionCommitteeInterface()),
                    );
                  },
                  child: const Text('Selection Committee Interface',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Student Interface Implementation
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(
                  className,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  const GamesScreen(
      {super.key, required this.schoolName, required this.className});

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
      'Chess'
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  const GameResultsScreen(
      {super.key,
      required this.schoolName,
      required this.className,
      required this.gameName});

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
                  borderRadius: BorderRadius.circular(15)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

// Selection Committee Interface Implementation
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
    'Chess'
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
                return DropdownMenuItem(
                  value: game,
                  child: Text(game),
                );
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
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
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
                          borderRadius: BorderRadius.circular(15)),
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
                        borderRadius: BorderRadius.circular(15)),
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
            MaterialPageRoute(builder: (context) => const StudentInterface()),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.bar_chart),
      ),
    );
  }
}
