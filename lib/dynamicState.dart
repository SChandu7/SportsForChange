import 'package:flutter/material.dart';

class dynamicState extends StatefulWidget {
  const dynamicState({super.key});

  @override
  State<dynamicState> createState() => _dynamicState();
}

class _dynamicState extends State<dynamicState> {
  Color containerColor = Colors.blue;
  int count = 0;
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
        backgroundColor: Colors.blue,
        title: const Text("dynamicState"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            color: containerColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20.20),
            child: InkWell(
              onTap: () {
                print("count is $count");
                count++;
                setState(() {});
              },
              child: Text(
                "$count",
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () {
                containerColor = Colors.red;
                setState(() {});
              },
              child: const Text("click to red")),
          ElevatedButton(
              onPressed: () {
                containerColor = Colors.green;
                setState(() {});
              },
              child: const Text("click to green")),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant dynamicState oldWidget) {
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
