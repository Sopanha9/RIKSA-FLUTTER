import 'package:flutter/material.dart';

void main() {
  try {
    DropdownMenu<String>(dropdownMenuEntries: []);
    debugPrint("No error");
  } catch (e) {
    debugPrint("Error: $e");
  }
}
