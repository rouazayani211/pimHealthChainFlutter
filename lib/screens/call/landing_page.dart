import 'package:HealthChain/screens/messages/chat_screen.dart';
import 'package:flutter/material.dart';
import 'call_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController callIDController = TextEditingController();
  final TextEditingController userIDController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Call'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: callIDController,
              decoration: const InputDecoration(
                hintText: "Enter Call ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: userIDController,
              decoration: const InputDecoration(
                hintText: "Enter User ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: userNameController,
              decoration: const InputDecoration(
                hintText: "Enter Your Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (callIDController.text.isEmpty ||
                    userIDController.text.isEmpty ||
                    userNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      callID: callIDController.text,
                      userID: userIDController.text,
                      userName: userNameController.text,
                      isCaller: false,
                    ),
                  ),
                );
              },
              child: const Text("Join the Call"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    callIDController.dispose();
    userIDController.dispose();
    userNameController.dispose();
    super.dispose();
  }
}
