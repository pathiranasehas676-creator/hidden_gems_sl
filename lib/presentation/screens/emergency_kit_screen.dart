import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';

class EmergencyKitScreen extends StatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  State<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends State<EmergencyKitScreen> {
  bool _isSendingSOS = false;

  final List<Map<String, String>> _emergencyContacts = [
    {"name": "Police Emergency", "number": "119", "desc": "National emergency line"},
    {"name": "Suwa Seriya", "number": "1990", "desc": "Free Ambulance Service"},
    {"name": "Tourist Police", "number": "011-2421451", "desc": "Special support for travelers"},
    {"name": "Accident Ward (Colombo)", "number": "011-2691111", "desc": "Main General Hospital"},
    {"name": "Fire & Rescue", "number": "110", "desc": "Municipal fire services"},
  ];

  Future<void> _handleSOS() async {
    setState(() => _isSendingSOS = true);
    
    try {
      // 1. Check/Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 2. Get Current Location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 3. Prepare Message
      final String mapLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      final String sosMessage = "EMERGENCY: I need help. My current location is: $mapLink (Sent via AdvanceTravel.me)";

      // 4. Send to SOS Contacts
      final profile = UserPreferenceService.getProfile();
      if (profile.sosContacts.isEmpty) {
        // Fallback to calling 119 if no contacts
        await launchUrl(Uri.parse("tel:119"));
      } else {
        // In a real app, we'd use a plugin like flutter_sms.
        // For now, we launch the SMS app for each contact.
        for (final contact in profile.sosContacts) {
          final Uri smsUri = Uri.parse("sms:$contact?body=${Uri.encodeComponent(sosMessage)}");
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SOS Alerts Prepared!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (context.mounted) setState(() => _isSendingSOS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency & Safety"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // SOS Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(opacity: 0.1, color: Colors.redAccent),
                  child: Column(
                    children: [
                      const Icon(Icons.emergency_share, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        "SOS Distress Alert",
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Triggers a location-tagged alert to your emergency contacts and local authorities.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSendingSOS ? null : _handleSOS,
                          child: _isSendingSOS
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("ACTIVATE SOS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  "Direct Emergency Lines",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.sigiriyaOchre),
                ),
                const SizedBox(height: 16),

                // Directory
                ..._emergencyContacts.map((contact) => _buildContactCard(contact)),

                const SizedBox(height: 24),
                _buildSOSContactManager(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.05),
      child: ListTile(
        title: Text(contact["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(contact["desc"]!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Container(
          decoration: BoxDecoration(color: AppTheme.sigiriyaOchre, borderRadius: BorderRadius.circular(8)),
          child: IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: () => launchUrl(Uri.parse("tel:${contact["number"]}")),
          ),
        ),
      ),
    );
  }

  Widget _buildSOSContactManager() {
    final profile = UserPreferenceService.getProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("My Emergency Contacts", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => _showAddContactDialog(),
              child: const Text("+ Add", style: TextStyle(color: AppTheme.sigiriyaOchre)),
            ),
          ],
        ),
        if (profile.sosContacts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("None added yet. Calls will default to 119.", style: TextStyle(color: Colors.white38, fontSize: 12)),
          )
        else
          Wrap(
            spacing: 8,
            children: profile.sosContacts.map((c) => Chip(
              label: Text(c, style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.white12,
              onDeleted: () async {
                final p = UserPreferenceService.getProfile();
                p.sosContacts.remove(c);
                await UserPreferenceService.saveProfile(p);
                setState(() {});
              },
            )).toList(),
          ),
      ],
    );
  }

  void _showAddContactDialog() {
    String phone = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add SOS Contact"),
        content: TextField(
          decoration: const InputDecoration(hintText: "Enter Phone Number"),
          keyboardType: TextInputType.phone,
          onChanged: (v) => phone = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (phone.isNotEmpty) {
                final p = UserPreferenceService.getProfile();
                p.sosContacts.add(phone);
                await UserPreferenceService.saveProfile(p);
                setState(() {});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
