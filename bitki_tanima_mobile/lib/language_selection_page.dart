// lib/language_selection_page.dart
import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatelessWidget {
  final void Function(String) onLangSelected;
  const LanguageSelectionPage({super.key, required this.onLangSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "Lütfen Dil Seçiniz\nPlease Select Language",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => onLangSelected("tr"),
                child: const Text("🇹🇷 Türkçe"),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => onLangSelected("en"),
                child: const Text("🇬🇧 English"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
