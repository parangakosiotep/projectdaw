// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- CONFIGURATION ---
// TODO: Replace with your actual Firebase Realtime Database URL
const String firebaseDatabaseUrl = "https://bulletin-bot-13059-default-rtdb.firebaseio.com";
const String adminPasskey = "0123";
// TODO: Securely handle your API key. For development, use it from environment.
const String geminiApiKey = "AIzaSyALncYDGvVT6JaoEWvpYu0NWQO_XV43utE"; 

// Initialize the database reference
// Must be done *after* Firebase is initialized in the main function.
late final DatabaseReference dbRef; 
final GenerativeModel _model = GenerativeModel(
  model: 'gemini-2.5-flash',
  apiKey: geminiApiKey,
);

void main() async {
  // Ensure that Firebase is initialized before using any Firebase services
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase Core (Requires platform-specific config)
  // TODO: Add your Firebase initialization logic here (e.g., using DefaultFirebaseOptions)
  await Firebase.initializeApp(); 

  // 2. Setup the Realtime Database reference
  dbRef = FirebaseDatabase.instance.ref();
  
  // 3. Run the Flutter App
  runApp(const BulletinBotApp());
}

class BulletinBotApp extends StatelessWidget {
  const BulletinBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barangay Bulletin Bot (Flutter)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandingPage(), // Start with the Landing Page
    );
  }
}

// --- STATEFUL WIDGETS (Where the Flet views would be) ---

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // State variables and methods like switch_to_admin/resident go here
  
  @override
  Widget build(BuildContext context) {
    // This is the equivalent of the Flet show_landing() function's UI
    return Scaffold(
      appBar: AppBar(title: const Text("🏘️ Barangay Bulletin Bot")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Firebase Realtime Database Persistence Enabled",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),
            const Divider(),
            const Text("Select your role:", style: TextStyle(fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // TODO: Implement on-press logic to navigate to Admin/Resident
                ElevatedButton(
                  onPressed: () { 
                    // Navigator.push... to Admin login
                  },
                  child: const Text("🛠 Admin"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () { 
                    // Navigator.push... to Resident view
                  },
                  child: const Text("👥 Resident"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Create AdminLoginPage, AdminPanelPage, ResidentViewPage, and AnalyticsPage