import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/batik_background.dart';
import '../../data/datasources/dynamic_content_service.dart';
import '../../data/datasources/admin_api_service.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await DynamicContentService.fetchEvents();
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  void _showEventForm({Map<String, dynamic>? event}) {
    final nameController = TextEditingController(text: event?['name'] ?? "");
    final typeController = TextEditingController(text: event?['type'] ?? "religious");
    final dateController = TextEditingController(text: event?['date'] ?? "");
    final locationController = TextEditingController(text: event?['location'] ?? "Island-wide");
    final descriptionController = TextEditingController(text: event?['description'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(event == null ? "Add Event" : "Edit Event", style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField("Name", nameController),
              _buildField("Type (religious/cultural/seasonal)", typeController),
              _buildField("Date (MM-DD) or Start/End", dateController),
              _buildField("Location", locationController),
              _buildField("Description", descriptionController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> newEvent = {
                "name": nameController.text,
                "type": typeController.text,
                "date": dateController.text,
                "location": locationController.text,
                "description": descriptionController.text,
              };
              
              final success = await AdminApiService.upsertEvent(newEvent);
              if (success && context.mounted) {
                Navigator.pop(context);
                _loadEvents();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOchre, foregroundColor: Colors.black),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentOchre)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      appBar: AppBar(
        title: Text("Manage Events", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadEvents, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BatikBackground(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOchre))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(event['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${event['type']} • ${event['date'] ?? 'Seasonal'}", style: const TextStyle(color: Colors.white60)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.white54), onPressed: () => _showEventForm(event: event)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent), 
                          onPressed: () async {
                             final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text("Delete Event?", style: TextStyle(color: Colors.white)),
                                  content: Text("Are you sure you want to delete ${event['name']}?", style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                             );
                             if (confirm == true) {
                               final docId = event['name'].toString().toLowerCase().replaceFirst(" ", "-");
                               final success = await AdminApiService.deleteEvent(docId);
                               if (success) _loadEvents();
                             }
                          }
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventForm(),
        backgroundColor: AppTheme.accentOchre,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
