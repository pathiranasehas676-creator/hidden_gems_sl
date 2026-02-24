import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/place_service.dart';
import '../services/location_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<Map<String, String>> _messages = [
    {"role": "ai", "content": "Ayu-bowan! I'm TripMate AI. How can I help you explore Sri Lanka today?"}
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _isThinking) return;
    
    setState(() {
      _messages.add({"role": "user", "content": text});
      _isThinking = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Prepare context
    final places = await PlaceService.loadPlaces();
    final pos = await LocationService.getCurrentLocation();
    
    final contextData = AiService.buildContext(
      userLat: pos?.latitude ?? 7.8731,
      userLng: pos?.longitude ?? 80.7718,
      radius: 50,
      nearbyPlaces: places,
      transportMode: "Car", // Default
      budgetLevel: "Medium",
    );

    final response = await AiService.getAiRecommendation(text, contextData);

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add({"role": "ai", "content": response});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1D1C) 
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text("TripMate AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                  child: const Text("PREMIUM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildThinkingIndicator();
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? Theme.of(context).colorScheme.primary 
                          : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B302F) : Colors.grey[100]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 20),
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildQuickOptions(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isThinking,
                    decoration: InputDecoration(
                      hintText: "Ask TripMate...",
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B302F) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isThinking ? null : () => _sendMessage(_controller.text),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B302F) : Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildQuickOptions() {
    final options = ["📅 Plan My Day", "🛡️ Safety Check", "💰 Budget Est.", "🛤️ Route Rec."];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(options[index]),
              onPressed: _isThinking ? null : () => _sendMessage(options[index]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
