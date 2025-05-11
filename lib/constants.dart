import 'package:flutter/material.dart';

class AppColors {
  static const Color primary0 = Color(0xFF000000);
  static const Color primary10 = Color(0xFF663300);
  static const Color primary20 = Color(0xFFFFD94D);
  static const Color primary30 = Color(0xFFF5C508);
  static const Color primary40 = Color(0xFFECECEC);
  static const Color primary50 = Color(0xFFFFFFFF);

  static const Color secondary0 = Color(0xFF000000);
  static const Color secondary10 = Color(0xFF1A1A1A);
  static const Color secondary20 = Color(0xFF333333);
  static const Color secondary30 = Color(0xFF4D4D4D);
  static const Color secondary40 = Color(0xFF808080);
  static const Color secondary50 = Color(0xFFB3B3B3);
  static const Color secondary60 = Color(0xFFECECEC);
  static const Color secondary70 = Color(0xFFF2F2F2);
}

class ProductClassification {
  static const List<String> categories = [
    "Academic materials",
    "Technology & electronics",
    "Transportation",
    "Clothing & accessories",
    "Housing",
    "Entertainment",
    "Sports & fitness",
    "Furniture",
    "Books",
    "Health & Beauty",
    "Music & Instruments",
    "Toys & Games",
    "Pet supplies",
    "Services",
    "Art & Collectibles",
    "Garden & Outdoor",
    "Food & Beverages",
  ];
}

class Careers {
  static const List<String> careers = [
    "Directed Studies",
    "Administration",
    "Economy",
    "Government and Public Affairs",
    "Biology",
    "Physics",
    "Geosciences",
    "Math",
    "Microbiology",
    "Chemistry",
    "Medicine",
    "Architecture",
    "Art",
    "Design",
    "History of Art",
    "Literature",
    "Music",
    "Digital Narratives",
    "Environmental Engineering",
    "Biomedical Engineering",
    "Civil Engineering",
    "Electrical Engineering",
    "Electronic Engineering",
    "Industrial Engineering",
    "Mechanical Engineering",
    "Chemical Engineering",
    "Systems and Computer Engineering ",
    "Law",
    "Anthropology",
    "Political Science",
    "Global Studies",
    "Philosophy",
    "History",
    "Languages and Culture",
    "Psychology",
    "Bachelor of Arts",
    "Bachelor of Biology",
    "Bachelor's Degree in Early Childhood Education",
    "Bachelor's Degree in Spanish and Philology",
    "Bachelor of Philosophy",
    "Bachelor's Degree in Physics",
    "Bachelor of History",
    "Bachelor of Mathematics",
    "Bachelor's Degree in Chemistry",
  ];
}

class ErrorMessages {
  static const String allFieldsRequired = 'All fields must be filled out';
  static const String invalidEmailDomain = 'You must use an @uniandes.edu.co email';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String weakPassword = 'Weak password';
  static const String maxChar = 'Maximum 40 characters allowed';
  static const String semesterRange = 'Invalid semester';
  static const String priceRange = 'Minimum price is \$1000';
}
