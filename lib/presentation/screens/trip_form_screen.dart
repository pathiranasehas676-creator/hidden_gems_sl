import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'loading_plan_screen.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController(text: '25000');

  String _origin = "";
  String _destination = "";
  int _days = 2;
  String _groupType = "couple";
  String _pace = "balanced";
  String _style = "comfort";
  String _transport = "any";
  final List<String> _interests = [];

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _groupOptions = ["solo", "couple", "family", "friends"];
  final List<String> _paceOptions = ["relaxed", "balanced", "packed"];
  final List<String> _styleOptions = ["budget", "comfort", "luxury"];
  final List<String> _interestOptions = [
    "Nature 🌿", "Beaches 🏖️", "History 🏛️", "Culture 🎭",
    "Adventure 🧗", "Food 🍛", "Wildlife 🐘", "Photography 📸",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.silkPearl,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            _prevStep();
          },
        ),
        title: _buildProgressBar(),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text("Exit", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _currentStep = i);
            },
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
            ],
          ),
          // Time-Aware Dynamic Overlay
          IgnorePointer(
            child: Container(
              color: AppTheme.getDynamicOverlay(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 140,
      height: 4,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 140 * ((_currentStep + 1) / _totalSteps),
            decoration: BoxDecoration(color: AppTheme.accentOchre, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _stepLayout(
      title: "Where should the\nOracle guide you?",
      subtitle: "The Essentials",
      content: Column(
        children: [
          _premiumTextField(label: "Starting Point", hint: "Airport, Colombo...", icon: Icons.flight_takeoff, onChanged: (v) => _origin = v),
          const SizedBox(height: 24),
          _premiumTextField(label: "Destination", hint: "Ella, Galle, Kandy...", icon: Icons.place_outlined, onChanged: (v) => _destination = v),
          const SizedBox(height: 32),
          _outlinedTile(icon: Icons.calendar_month, label: "Start Date", value: _formatDate(_startDate), onTap: _pickDate),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _stepLayout(
      title: "Define the vibe of\nyour journey.",
      subtitle: "Budget & Style",
      content: Column(
        children: [
          _itemHeader("DAILY DURATION"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("How many days?", style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
              Text("$_days Days", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentOchre)),
            ],
          ),
          Slider(
            value: _days.toDouble(),
            min: 1, max: 21, divisions: 20,
            activeColor: AppTheme.primaryBlue,
            onChanged: (v) => setState(() => _days = v.toInt()),
          ),
          const SizedBox(height: 32),
          _choiceGroup("Travel Standard", _styleOptions, _style, (v) => setState(() => _style = v)),
          const SizedBox(height: 32),
          _budgetField(),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _stepLayout(
      title: "With whom do you\ntread the path?",
      subtitle: "Companions & Pace",
      content: Column(
        children: [
          _choiceGroup("Companions", _groupOptions, _groupType, (v) => setState(() => _groupType = v)),
          const SizedBox(height: 32),
          _choiceGroup("Travel Pace", _paceOptions, _pace, (v) => setState(() => _pace = v)),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return _stepLayout(
      title: "What stirs the soul\nof your traveler?",
      subtitle: "Interests & Passions",
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _interestOptions.map((opt) {
          final isSelected = _interests.contains(opt);
          return FilterChip(
            label: Text(opt, style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : AppTheme.primaryBlue,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
            selected: isSelected,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              setState(() => val ? _interests.add(opt) : _interests.remove(opt));
            },
            selectedColor: AppTheme.primaryBlue,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        }).toList(),
      ),
    );
  }

  Widget _stepLayout({required String title, required String subtitle, required Widget content}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accentOchre, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, height: 1.2)),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  Widget _premiumTextField({required String label, required String hint, required IconData icon, required Function(String) onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: TextFormField(
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.accentOchre),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _budgetField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ESTIMATED BUDGET", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _budgetController,
            style: AppTheme.budgetEmphasis,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: "LKR ", border: InputBorder.none),
          ),
        ],
      ),
    );
  }

  Widget _choiceGroup(String label, List<String> options, String current, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _itemHeader(label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: options.map((opt) {
            final isSelected = current == opt;
            return ChoiceChip(
              label: Text(opt.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelect(opt),
              selectedColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _itemHeader(String label) => Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1));

  Widget _outlinedTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentOchre),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F1F1)))),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _nextStep();
        },
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
        child: Text(_currentStep == _totalSteps - 1 ? "CONSULT ORACLE" : "CONTINUE"),
      ),
    );
  }

  void _submit() {
    final budgetLkr = int.tryParse(_budgetController.text) ?? 25000;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingPlanScreen(
          origin: _origin.isEmpty ? "Colombo" : _origin,
          destination: _destination.isEmpty ? "Kandy" : _destination,
          days: _days,
          startDate: _formatDate(_startDate),
          groupType: _groupType,
          pace: _pace,
          budgetLkr: budgetLkr,
          style: _style,
          transport: "car",
          interests: _interests.isEmpty ? ["Nature 🌿"] : _interests,
          mustInclude: const [],
          avoid: const [],
          constraints: const [],
        ),
      ),
    );
  }
}
