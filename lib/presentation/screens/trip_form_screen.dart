import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/batik_background.dart';
import '../widgets/custom_buttons.dart';
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

  final _budgetController = TextEditingController(text: '25000');

  String _origin = "";
  String _destination = "";
  int _days = 2;
  String _groupType = "couple";
  String _pace = "balanced";
  String _style = "comfort";
  final List<String> _interests = [];

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _groupOptions = ["solo", "couple", "family", "friends"];
  final List<String> _paceOptions = ["relaxed", "balanced", "packed"];
  final List<String> _styleOptions = ["budget", "comfort", "luxury"];
  final List<String> _interestOptions = [
    "Nature 🌿", "Beaches 🏖️", "History 🏛️", "Culture 🎭",
    "Adventure 🧗", "Food 🍛", "Wildlife 🐘", "Photography 📸",
  ];

  // Sri Lanka cities for autocomplete — offline, no network needed
  static const List<String> _sriLankaCities = [
    'Colombo', 'Galle', 'Kandy', 'Ella', 'Nuwara Eliya', 'Jaffna', 'Trincomalee',
    'Batticaloa', 'Negombo', 'Anuradhapura', 'Polonnaruwa', 'Sigiriya', 'Dambulla',
    'Matara', 'Hambantota', 'Tangalle', 'Mirissa', 'Weligama', 'Hikkaduwa',
    'Unawatuna', 'Arugam Bay', 'Habarana', 'Pinnawala', 'Ratnapura', 'Kurunegala',
    'Bandarawela', 'Badulla', 'Monaragala', 'Ampara', 'Mannar', 'Vavuniya',
    'Kataragama', 'Tissamaharama', 'Bentota', 'Beruwala', 'Chilaw', 'Kalpitiya',
    'Puttalam', 'Avissawella', 'Hatton', 'Nanu Oya', 'Ohiya',
    'BIA / Airport', 'Katunayake',
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Theme.of(context).colorScheme.primary),
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
            child: Text("Exit", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: BatikBackground(
          child: Stack(
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
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 140,
      height: 6,
      decoration: BoxDecoration(color: AppTheme.modernGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 140 * ((_currentStep + 1) / _totalSteps),
            decoration: BoxDecoration(
              gradient: AppTheme.modernGradient, 
              borderRadius: BorderRadius.circular(3),
            ),
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
          _cityAutocomplete(
            label: "Starting Point",
            hint: "Airport, Colombo...",
            icon: Icons.flight_takeoff,
            onSelected: (v) => _origin = v,
          ),
          const SizedBox(height: 24),
          _cityAutocomplete(
            label: "Destination",
            hint: "Ella, Galle, Kandy...",
            icon: Icons.place_outlined,
            onSelected: (v) => _destination = v,
          ),
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
              Text("How many days?", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText.withOpacity(0.6))),
              Text("$_days Days", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.modernGreen)),
            ],
          ),
          Slider(
            value: _days.toDouble(),
            min: 1, max: 21, divisions: 20,
            activeColor: AppTheme.modernGreen,
            inactiveColor: AppTheme.modernGreen.withOpacity(0.1),
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
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
            selected: isSelected,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              setState(() => val ? _interests.add(opt) : _interests.remove(opt));
            },
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2)),
            ),
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
          Text(subtitle.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, height: 1.2)),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  /// City autocomplete field using local Sri Lanka dataset
  Widget _cityAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onSelected,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return const Iterable.empty();
        return _sriLankaCities.where((city) => city.toLowerCase().contains(query));
      },
      onSelected: (val) {
        HapticFeedback.selectionClick();
        onSelected(val);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: AppTheme.glassDecoration(
            color: Theme.of(context).cardColor,
            opacity: Theme.of(context).brightness == Brightness.light ? 0.8 : 0.2,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (v) => onSelected(v),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(color: AppTheme.darkText.withOpacity(0.7)),
              hintStyle: TextStyle(color: AppTheme.darkText.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: AppTheme.modernBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.modernBlue.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.modernBlue.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.modernBlue, width: 2),
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: MediaQuery.of(context).size.width - 64,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final city = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.sigiriyaOchre),
                          const SizedBox(width: 10),
                          Text(city, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _budgetField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.modernBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ESTIMATED BUDGET", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _budgetController,
            style: AppTheme.budgetEmphasis.copyWith(color: Theme.of(context).colorScheme.onSurface),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "LKR ", 
              prefixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              border: InputBorder.none
            ),
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
          spacing: 12,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = current == opt;
            return ChoiceChip(
              label: Text(opt.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelect(opt),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, 
                fontWeight: FontWeight.bold, 
                fontSize: 11,
              ),
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              elevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _itemHeader(String label) => Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), letterSpacing: 1));

  Widget _outlinedTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(top: BorderSide(color: AppTheme.modernGreen.withOpacity(0.05)))
      ),
      child: PrimaryButton(
        label: _currentStep == _totalSteps - 1 ? "CONSULT ORACLE" : "CONTINUE",
        onPressed: () {
          HapticFeedback.lightImpact();
          _nextStep();
        },
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
