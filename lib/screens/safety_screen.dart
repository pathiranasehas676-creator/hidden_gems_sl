import 'package:flutter/material.dart';
import '../services/safety_service.dart';

class SafetyScreen extends StatelessWidget {
  final String district;

  const SafetyScreen({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    final safetyInfo = SafetyService.getSafetyInfo(district);
    final statusColor = safetyInfo['status'].toString().contains('Caution')
        ? Colors.amber
        : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Advisory"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(safetyInfo['status'], statusColor),
            const SizedBox(height: 32),
            const Text(
              "Local Precautions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ... (safetyInfo['precautions'] as List<String>).map((p) => _buildPrecautionItem(p)),
            const SizedBox(height: 32),
            _buildEmergencyContactCard(context, safetyInfo['emergency']),
            const SizedBox(height: 32),
            _buildGeneralTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: color, size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Safety Status",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecautionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context, String numbers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_share, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Emergency Contacts",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            numbers,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // In real app, launch caller
            },
            icon: const Icon(Icons.call),
            label: const Text("Call 1990 (Ambulance)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sri Lanka Travel Tips",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "1. Respect local customs and religious sites.\n2. Stay hydrated with King Coconut water.\n3. Keep your passport and valuables in a safe place.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
