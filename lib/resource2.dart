import 'package:flutter/material.dart';

class resource with ChangeNotifier {
  String PresentWorkingUser = 'admin';

  void setLoginDetails(String user) {
    PresentWorkingUser = user;
    notifyListeners(); // Notify widgets listening to this model
  }
}
