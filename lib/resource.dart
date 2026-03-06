import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class resource with ChangeNotifier {
  String PresentWorkingUser = 'defaultUser';
  String Presentschool = 'Not Avaible ';

  void setptschool(String school) {
    Presentschool = school;
    notifyListeners(); // Notify widgets listening to this model
  }

  void setLoginDetails(String user) {
    PresentWorkingUser = user;
    notifyListeners(); // Notify widgets listening to this model
  }
}
