import 'package:flutter/material.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  _HomePageState2 createState() => _HomePageState2();
}

class _HomePageState2 extends State<HomePage2> {
  bool isBlockVisible = false; // State to toggle visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expandable Block Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isBlockVisible = !isBlockVisible; // Toggle visibility
                });
              },
              child: Text(isBlockVisible ? 'Hide Block' : 'Show Block'),
            ),
            const SizedBox(height: 20),
            if (isBlockVisible) // Show this block only if `isBlockVisible` is true
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Block Content',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                        'This is a block of content that can contain text, buttons, or anything else.'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        print("Block button pressed!");
                      },
                      child: const Text("Block Button"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
