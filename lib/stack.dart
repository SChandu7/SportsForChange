import 'package:flutter/material.dart';

class stack extends StatelessWidget {
  const stack({super.key, required});
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Center(
          child: Text(
            "Registration Form", //registration name
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  color: Colors.red,
                ),
                Container(
                  height: 80,
                  width: 80,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
