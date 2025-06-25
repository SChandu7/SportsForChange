import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//stl for defualt class  input
class test extends StatelessWidget {
  const test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(80.0),
            child: InkWell(
                onDoubleTap: () {
                  print("alarm clicked");
                },
                child: const Icon(Icons.alarm, size: 50, color: Colors.red)),
          ),
          GestureDetector(
              onDoubleTap: () {
                print("thumup clicked");
              },
              child: const Icon(Icons.thumb_up,
                  size: 50, color: Color.fromARGB(255, 80, 38, 35))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_down)),
          Text(
            "click me",
            style: GoogleFonts.poorStory().copyWith(fontSize: 30),
          ),
          TextButton(
              onPressed: () {
                print("clicked");
              },
              child: const Text("clickme")),
          const Padding(
            padding: EdgeInsets.all(56.0),
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter Email",
                labelText: "E-Mail",
                prefixIcon: Icon(Icons.mail),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: "Enter Phone",
                labelText: "Phone Number",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
