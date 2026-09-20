import 'package:flutter/material.dart';
void main() {
  try {
    DropdownMenu<String>(dropdownMenuEntries: []);
    print("No error");
  } catch (e) {
    print("Error: $e");
  }
}
