import 'package:flutter/material.dart';
import '../services/budget_service.dart';
import '../models/place.dart';

class BudgetScreen extends StatelessWidget {
  final List<Place> selectedPlaces;
  final double totalDistance;
  final String transportMode;

  const BudgetScreen({
    super.key,
    required this.selectedPlaces,
    required this.totalDistance,
    required this.transportMode,
  });

  @override
  Widget build(BuildContext context) {
    final estimate = BudgetService.calculateEstimate(
      totalDistance: totalDistance,
      transportMode: transportMode,
      targetPlaces: selectedPlaces,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cost Estimate"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalCard(context, estimate['total']),
            const SizedBox(height: 24),
            const Text(
              "Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEstimateItem(
              context,
              Icons.local_gas_station,
              "Fuel / Transport",
              "LKR ${estimate['fuelCost']}",
              "Calculated for $transportMode over ${totalDistance.toStringAsFixed(1)}km",
            ),
            _buildEstimateItem(
              context,
              Icons.confirmation_number_outlined,
              "Entrance Tickets",
              "LKR ${estimate['ticketCost']}",
              "Approximate for ${selectedPlaces.length} locations",
            ),
            _buildEstimateItem(
              context,
              Icons.local_parking,
              "Parking Fees",
              "LKR ${estimate['parkingCost']}",
              "Average local rates",
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "These are estimated costs and may vary based on actual traffic, seasonal ticket price changes, and transport availability.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, String total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Estimated Trip Cost",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "LKR $total",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateItem(
    BuildContext context,
    IconData icon,
    String title,
    String amount,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
