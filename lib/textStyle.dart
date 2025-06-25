import 'package:flutter/material.dart';

class textStyle extends StatelessWidget {
  const textStyle({super.key});
  @override
  Widget build(context) {
    return Center(
      child: Container(
          alignment: Alignment.center,
          // color: Colors.green,
          margin: const EdgeInsets.all(40),
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.blue, width: 10),
            color: Colors.green,
          ),
          // padding: EdgeInsets.symmetric(vertical: 80.0),
          /* child: Text('Hello Wolrd2',
              style:
                  TextStyle(color: Color.fromRGBO(28, 2, 2, 1), fontSize: 28)*/
          child: const Icon(
            Icons.airplanemode_on,
            size: 60,
          )),
    );
  }
}


/*ThreeDPushableButton(
              text: "Click Me!",
              buttonColor: Colors.blue,
              shadowColor: Colors.black,
              onPressed: () {
                // Add the desired functionality here
                print("3D Button Pressed!");
              },
            ),
            const SizedBox(height: 20),
            // Add more widgets as needed
            const Text(
              "Other Content Here",
              style: TextStyle(fontSize: 18),
            ), */