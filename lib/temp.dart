import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class temp extends StatefulWidget {
  const temp({super.key});

  @override
  State<temp> createState() => _temp();
}

class _temp extends State<temp> {
  Color containerColor = Colors.blue;
  int count = 0;
  bool eye = true;
  XFile? fil;
  String textt = "Submit";

  @override
  void initState() {
    print("initState called");
    // calls only once

    // api data fetching, runtime permission, locations, etc
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // call mutlple times
    print("didChangeDependencies called");
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print('build called');
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 50, 0, 40),
                child: Text(
                  "Welcome To the Registration Form", //welcome
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            /* Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 50,
                  ),
                ),
                Positioned(
                  bottom: 45,
                  right: 5,
                  child: InkWell(
                      onDoubleTap: () async {
                        ImagePicker imgpic = ImagePicker();
                        fil =await imgpic.pickImage(source: ImageSource.gallery);
                        setState(() {});
                        if (fil != null)
                          print("Image  picked ");
                        else
                          print("Iamge is Not Picked");
                        print("camera clicked");
                      },
                      child: Icon(Icons.camera)),
                ),
              ],
            ),*/
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                keyboardType: TextInputType.name,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: "Enter Name",
                  labelText: "Name",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: "Enter Email",
                  labelText: "Email",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                keyboardType: TextInputType.name,
                obscureText: eye,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: "Enter Password",
                  labelText: "Password",
                  counterText: "",
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
                      child: Icon((eye == true)
                          ? Icons.visibility_off
                          : Icons.visibility)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  print("clicked");
                  textt = "Submited";
                  setState(() {});
                },
                child: Text(textt)),
            Stack(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  color: Colors.black,
                ),
                Positioned(
                  bottom: 5,
                  left: 4.5,
                  child: Container(
                    height: 40,
                    width: 40,
                    color: Colors.red,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant temp oldWidget) {
    print("didUpdateWidget called");
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    print("dispose called");
    // close all the resource
    // TODO: implement dispose
    super.dispose();
  }
}
