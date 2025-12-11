import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:math';

// --- CONFIGURATION ---
const String firebaseDatabaseUrl = "https://bulletin-bot-13059-default-rtdb.firebaseio.com";
const String adminPasskey = "0123";
const String geminiApiKey = "AIzaSyC41buG9QWttPsYuGhdaSo2I16_cn9"; 

// --- GLOBAL DATA MANAGER (Mimicking Python Globals) ---
class DataManager {
  static List<String> adminSummaries = [];
  static List<String> residentSummaries = [];
  static List<String> residentFeedback = [];
  
  static final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // Helper to safely convert Firebase object/dict/list to List<String>
  static List<String> _toList(dynamic firebaseValue) {
    if (firebaseValue == null) return [];
    if (firebaseValue is List) {
      return firebaseValue.map((e) => e.toString()).toList();
    }
    if (firebaseValue is Map) {
      // Realtime DB can store lists as maps with index keys (0, 1, 2...)
      // We sort by key to maintain order
      final sortedKeys = firebaseValue.keys.toList()..sort();
      return sortedKeys.map((k) => firebaseValue[k].toString()).toList();
    }
    return [];
  }

  static Future<void> loadData() async {
    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        final adminData = data['admin_data'] as Map<dynamic, dynamic>? ?? {};
        final residentData = data['resident_data'] as Map<dynamic, dynamic>? ?? {};

        adminSummaries = _toList(adminData['admin_summaries']);
        residentSummaries = _toList(adminData['resident_summaries']);
        residentFeedback = _toList(residentData['resident_feedback']);
        
        debugPrint("Data loaded: ${adminSummaries.length} announcements, ${residentFeedback.length} feedback items.");
      } else {
        // Initialize empty if DB is empty
        adminSummaries = [];
        residentSummaries = [];
        residentFeedback = [];
      }
    } catch (e) {
      debugPrint("Error loading data from Firebase: $e");
    }
  }

  static Future<void> saveData() async {
    try {
      final dataToSave = {
        'admin_data': {
          'admin_summaries': adminSummaries,
          'resident_summaries': residentSummaries
        },
        'resident_data': {
          'resident_feedback': residentFeedback
        }
      };
      await dbRef.set(dataToSave);
    } catch (e) {
      debugPrint("Error saving data to Firebase: $e");
    }
  }

  static Future<void> clearAllData() async {
    adminSummaries.clear();
    residentSummaries.clear();
    residentFeedback.clear();
    try {
      await dbRef.set({});
    } catch (e) {
      debugPrint("Error clearing root DB: $e");
    }
  }

  static Future<List<String>> checkPersistenceStatus() async {
    try {
      final snapshot = await dbRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        return ["✅ Firebase Connected: Database is empty (0 bytes)."];
      }
      
      // Estimate size roughly similar to sys.getsizeof
      final jsonString = jsonEncode(snapshot.value);
      final byteSize = utf8.encode(jsonString).length;

      return [
        "✅ Firebase Connected. Data size: ~$byteSize bytes.",
        "Admin Summaries: ${adminSummaries.length}",
        "Resident Feedback: ${residentFeedback.length}"
      ];
    } catch (e) {
      return ["❌ Firebase Error: $e"];
    }
  }
}

// --- GEMINI HELPER ---
Future<String> summarizeText(String text) async {
  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
    final content = [Content.text("Summarize the following community announcement into 2–3 clear, factual bullet points:\n\n$text")];
    final response = await model.generateContent(content);
    return response.text ?? "No summary generated.";
  } catch (e) {
    return "Error generating summary: $e";
  }
}

// --- ANALYTICS LOGIC ---
Map<String, int> analyzeFeedback(List<String> feedbackList) {
  int positive = 0;
  int negative = 0;
  int neutral = 0;

  for (var feedback in feedbackList) {
    final text = feedback.toLowerCase();
    if (["good", "great", "excellent", "love", "helpful", "perfect"].any((w) => text.contains(w))) {
      positive++;
    } else if (["bad", "fix", "issue", "problem", "broken", "slow", "lag", "error"].any((w) => text.contains(w))) {
      negative++;
    } else {
      neutral++;
    }
  }
  return {"Positive": positive, "Negative": negative, "Neutral": neutral};
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initial load
    await DataManager.loadData();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  runApp(const BulletinBotApp());
}

class BulletinBotApp extends StatelessWidget {
  const BulletinBotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barangay Bulletin Bot (Firebase RTDB)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

// --- PAGES ---

// 1. LANDING PAGE
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏘️ Barangay Bulletin Bot")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "🏘️ Barangay Bulletin Bot",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Firebase Realtime Database Persistence Enabled",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Divider(indent: 50, endIndent: 50),
            const SizedBox(height: 20),
            const Text("Select your role:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () { 
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text("🛠 Admin"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () { 
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResidentViewPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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

// 2. ADMIN LOGIN
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _passkeyController = TextEditingController();
  bool _obscureText = true;

  void _attemptLogin() {
    if (_passkeyController.text == adminPasskey) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminPanelPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Incorrect passkey"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔐 Admin Access")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🔐 Admin Access", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Enter the passkey to continue", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _passkeyController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "🔑 Enter Admin Passkey",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _attemptLogin, child: const Text("Unlock Admin Panel")),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios),
              label: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. ADMIN PANEL
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final TextEditingController _announcementController = TextEditingController();
  String _summaryOutput = "";
  List<String> _statusLines = ["Checking status..."];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await DataManager.loadData();
    final status = await DataManager.checkPersistenceStatus();
    setState(() {
      _statusLines = status;
    });
  }

  Future<void> _handleSummarize() async {
    if (_announcementController.text.trim().isEmpty) return;
    
    final summary = await summarizeText(_announcementController.text);
    setState(() {
      _summaryOutput = summary;
      DataManager.adminSummaries.add(summary);
    });
    await DataManager.saveData();
    _announcementController.clear();
  }

  Future<void> _publishToResidents() async {
    // Find new summaries that aren't in resident list yet
    final newSummaries = DataManager.adminSummaries
        .where((s) => !DataManager.residentSummaries.contains(s))
        .toList();
    
    if (newSummaries.isNotEmpty) {
      setState(() {
        DataManager.residentSummaries.addAll(newSummaries);
      });
      await DataManager.saveData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Published ${newSummaries.length} new announcements."), backgroundColor: Colors.green),
      );
      // Navigate to resident view to show result
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ResidentViewPage()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No new drafts to publish.")),
      );
    }
  }

  Future<void> _clearAllData() async {
    await DataManager.clearAllData();
    setState(() {
      _summaryOutput = "";
    });
    await _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🧹 All app data cleared."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛠 Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  const Text("Firebase Realtime Database Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ..._statusLines.map((l) => Text(l, style: const TextStyle(fontSize: 10))),
                ],
              ),
            ),
            const Divider(height: 30),
            
            // Summarization Section
            const Text("1. Text Summarization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _announcementController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "📢 Paste Announcement",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handleSummarize,
              child: const Text("🧠 Summarize & Draft"),
            ),
            const SizedBox(height: 10),
            const Text("Draft Summary Preview", style: TextStyle(fontSize: 16)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_summaryOutput.isEmpty ? "No summary yet." : _summaryOutput),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _publishToResidents,
              child: const Text("📢 Publish Drafts"),
            ),
            const Divider(height: 30),

            // Feedback Management
            const Text("2. Resident Feedback Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DataManager.residentFeedback.isNotEmpty ? Colors.amber : Colors.grey[300],
                foregroundColor: Colors.black,
              ),
              child: Text("View Feedback & Analytics (${DataManager.residentFeedback.length})"),
            ),
            const Divider(height: 30),

            // Navigation & Actions
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResidentViewPage())),
                  child: const Text("👥 Switch to Resident View"),
                ),
                ElevatedButton(
                  onPressed: _clearAllData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                  child: const Text("🧹 Clear All Data"),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.arrow_back_ios),
                  label: const Text("Back to Home"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// 4. RESIDENT VIEW
class ResidentViewPage extends StatefulWidget {
  const ResidentViewPage({super.key});
  @override
  State<ResidentViewPage> createState() => _ResidentViewPageState();
}

class _ResidentViewPageState extends State<ResidentViewPage> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DataManager.loadData();
    setState(() {});
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) return;

    final dummyWords = ["love this feature", "needs a fix", "ok", "great idea"];
    final randomWord = dummyWords[Random().nextInt(dummyWords.length)];
    final finalFeedback = "${_feedbackController.text} ($randomWord)";

    setState(() {
      DataManager.residentFeedback.add(finalFeedback);
    });
    await DataManager.saveData();
    
    _feedbackController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Feedback submitted to Realtime DB! Thank you."), backgroundColor: Colors.blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👥 Resident View")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Community Announcements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (DataManager.residentSummaries.isEmpty)
              const Text("No announcements yet.")
            else
              ...DataManager.residentSummaries.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  // ignore: deprecated_member_use
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                ),
                child: Text(s, style: const TextStyle(fontSize: 14)),
              )),
            
            const Divider(height: 30),
            const Text("✍️ Submit Anonymous Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue)),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Feedback/Suggestion",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text("Submit Feedback"),
            ),
            const Divider(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.arrow_back_ios),
              label: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. ANALYTICS PAGE
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, int> _sentimentData = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DataManager.loadData();
    setState(() {
      _sentimentData = analyzeFeedback(DataManager.residentFeedback);
    });
  }

  Future<void> _clearFeedback() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Confirm Action"),
        content: const Text("Are you sure you want to clear ALL resident feedback?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Clear All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        DataManager.residentFeedback.clear();
        _sentimentData = analyzeFeedback([]);
      });
      await DataManager.saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ All resident feedback cleared."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildBar(String label, int count, Color color, int maxCount) {
    final double percentage = maxCount > 0 ? count / maxCount : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 30, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
                    FractionallySizedBox(
                      widthFactor: percentage == 0 ? 0.01 : percentage, // Ensure tiny visibility if 0 for layout stability or handle logic
                      child: Container(
                        height: 30,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                        child: Text("$label: $count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _sentimentData.values.isEmpty ? 1 : _sentimentData.values.reduce(max);
    
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Analytics")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("📊 Resident Feedback Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios),
                  label: const Text("Back to Admin"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _clearFeedback, style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]), child: const Text("🗑️ Clear All Feedback")),
              ],
            ),
            const Divider(),
            const Text("📈 Feedback Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Total Submissions: ${DataManager.residentFeedback.length}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            
            // Custom Bar Chart
            _buildBar("Positive", _sentimentData["Positive"] ?? 0, Colors.greenAccent.shade700, maxCount),
            _buildBar("Negative", _sentimentData["Negative"] ?? 0, Colors.redAccent.shade400, maxCount),
            _buildBar("Neutral", _sentimentData["Neutral"] ?? 0, Colors.blueGrey, maxCount),

            const Divider(height: 30),
            const Text("📝 Detailed Resident Feedback List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 300,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: ListView.builder(
                itemCount: DataManager.residentFeedback.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[100],
                    child: Text("#${index + 1}: ${DataManager.residentFeedback[index]}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}