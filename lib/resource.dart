import 'package:flutter/material.dart';

class resource with ChangeNotifier {
  String PresentWorkingUser = 'defaultUser';

  void setLoginDetails(String user) {
    PresentWorkingUser = user;
    notifyListeners(); // Notify widgets listening to this model
  }
}
