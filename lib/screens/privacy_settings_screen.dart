import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareLocation = true;
  bool _anonymousUsage = false;
  bool _offlineMaps = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & settings"),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Privacy Controls",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          SwitchListTile(
            title: const Text("Share Location"),
            subtitle: const Text("Allow the app used GPS to find gems near you"),
            value: _shareLocation,
            onChanged: (val) => setState(() => _shareLocation = val),
          ),
          SwitchListTile(
            title: const Text("Anonymous Usage Data"),
            subtitle: const Text("Help us improve by sending diagnostic data"),
            value: _anonymousUsage,
            onChanged: (val) => setState(() => _anonymousUsage = val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Data & Offline",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          SwitchListTile(
            title: const Text("Offline Cache"),
            subtitle: const Text("Keep visited places available offline"),
            value: _offlineMaps,
            onChanged: (val) => setState(() => _offlineMaps = val),
          ),
          ListTile(
            title: const Text("Clear Cache"),
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () {
              // Show confirmation
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "About",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          const ListTile(
            title: Text("Version"),
            trailing: Text("1.0.0"),
          ),
          const ListTile(
            title: Text("Privacy Policy"),
            trailing: Icon(Icons.open_in_new, size: 16),
          ),
        ],
      ),
    );
  }
}
