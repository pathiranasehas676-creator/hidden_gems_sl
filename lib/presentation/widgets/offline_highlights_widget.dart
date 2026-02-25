import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Inline KB data for completely offline use.
/// Mirrors the top-level structure from backend/kb_data.py.
/// No network required — rendered directly from this map.
const Map<String, Map<String, dynamic>> _kbOffline = {
  'ella': {
    'must_see': ['Nine Arch Bridge', 'Little Adam\'s Peak', 'Ella Rock', 'Ravana Falls'],
    'indoor': ['Chill Cafe', 'Ella Spice Garden cooking class'],
    'safety': 'Leeches on hiking trails after rain. Wear leech socks.',
    'emoji': '🏔️',
  },
  'sigiriya': {
    'must_see': ['Sigiriya Rock Fortress', 'Pidurangala Rock', 'Minneriya Safari'],
    'indoor': ['Sigiriya Museum', 'Village tour'],
    'safety': 'Wasps near the fortress. Move slowly if disturbed.',
    'emoji': '🗿',
  },
  'kandy': {
    'must_see': ['Temple of the Tooth', 'Peradeniya Botanical Gardens', 'Udawatta Kele Sanctuary'],
    'indoor': ['Kandyan Arts Museum', 'Cultural Dance Show'],
    'safety': 'Traffic is heavy. Use tuk tuk for short hops.',
    'emoji': '🏛️',
  },
  'galle': {
    'must_see': ['Galle Fort', 'Stilt fishermen', 'Unawatuna Beach'],
    'indoor': ['Galle Maritime Museum', 'Dutch Reformed Church'],
    'safety': 'Ocean currents strong south of fort. Swim at Unawatuna only.',
    'emoji': '⚓',
  },
  'mirissa': {
    'must_see': ['Mirissa Beach', 'Whale watching boat tour', 'Parrot Rock'],
    'indoor': ['Beach-side restaurants', 'Coconut Tree Hill viewpoint'],
    'safety': 'Whale watching boats run Nov–Apr. Book in advance.',
    'emoji': '🐋',
  },
  'nuwara eliya': {
    'must_see': ['Victoria Park', 'Tea factory tour', 'Gregory Lake'],
    'indoor': ['Tea factory museums', 'Pedro Tea Estate', 'Post Office'],
    'safety': 'Cold year-round. Bring a jacket. Altitude sickness rare but watch for it.',
    'emoji': '🍵',
  },
  'colombo': {
    'must_see': ['Galle Face Green', 'Pettah Market', 'Gangaramaya Temple'],
    'indoor': ['National Museum', 'Arcade Independence Square'],
    'safety': 'Standard city care. Use metered taxis or PickMe app.',
    'emoji': '🌆',
  },
  'bentota': {
    'must_see': ['Bentota Beach', 'Madhu River Safari', 'Brief Garden'],
    'indoor': ['Ayurvedic spa', 'Lunuganga tour'],
    'safety': 'Avoid unauthorised guides on the beach.',
    'emoji': '🏖️',
  },
  'hikkaduwa': {
    'must_see': ['Coral Sanctuary', 'Turtle Hatchery', 'Hikkaduwa Lake'],
    'indoor': ['Tsunami Photo Museum', 'Jewellery shops'],
    'safety': 'Touching coral is illegal. Strong currents in some areas.',
    'emoji': '🐢',
  },
  'yala': {
    'must_see': ['Yala National Park Safari', 'Sithulpawwa Rock Temple'],
    'indoor': ['Visitor Centre'],
    'safety': 'Never exit the jeep on safari. Leopard country.',
    'emoji': '🐆',
  },
};

class OfflineHighlightsWidget extends StatelessWidget {
  final String destination;
  const OfflineHighlightsWidget({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final key = destination.toLowerCase().trim();
    final data = _kbOffline[key];
    if (data == null) return const SizedBox.shrink();

    final mustSee = (data['must_see'] as List).cast<String>();
    final indoor = (data['indoor'] as List).cast<String>();
    final safety = data['safety'] as String;
    final emoji = data['emoji'] as String;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Text(emoji, style: const TextStyle(fontSize: 22)),
          title: Text(
            '$destination — Offline Highlights',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
          ),
          subtitle: const Row(
            children: [
              Icon(Icons.wifi_off, size: 11, color: Colors.orange),
              SizedBox(width: 4),
              Text('From local knowledge base',
                  style: TextStyle(fontSize: 11, color: Colors.orange)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('📍 Must See', mustSee, Colors.blue.shade700),
                  const SizedBox(height: 10),
                  _section('🌧️ Rainy Day Indoor', indoor, Colors.green.shade700),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(safety,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade700)),
                        ),
                      ],
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

  Widget _section(String label, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.25), width: 1),
                    ),
                    child: Text(item,
                        style: TextStyle(fontSize: 11, color: color)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
