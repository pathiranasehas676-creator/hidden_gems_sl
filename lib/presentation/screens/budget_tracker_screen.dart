import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';
import '../../data/datasources/trip_cache_service.dart';

class BudgetTrackerScreen extends StatefulWidget {
  final TripPlan plan;
  final String? planId; // If null, it's the volatile 'last plan'

  const BudgetTrackerScreen({super.key, required this.plan, this.planId});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: "Rs. ", decimalDigits: 0);

  int get _totalSpent => widget.plan.realizedExpenses.fold(0, (sum, e) => sum + e.amountLkr);
  int get _budget => widget.plan.tripSummary.userBudgetLkr;
  double get _percentUsed => _budget > 0 ? (_totalSpent / _budget).clamp(0.0, 1.0) : 0.0;

  void _addExpense() {
    String title = "";
    int amount = 0;
    String category = "food";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: AppTheme.glassDecoration(opacity: 0.98, color: const Color(0xFF1A1D1C)),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Expense", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("What did you buy?"),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: AppTheme.sigiriyaOchre, fontWeight: FontWeight.bold),
                decoration: _inputDecoration("Amount (LKR)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
              initialValue: category,
                dropdownColor: AppTheme.darkCard,
                decoration: _inputDecoration("Category"),
                items: ["food", "transport", "tickets", "misc"].map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)),
                )).toList(),
                onChanged: (v) => setModalState(() => category = v!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (title.isNotEmpty && amount > 0) {
                      final newExpense = Expense(
                        id: const Uuid().v4(),
                        title: title,
                        amountLkr: amount,
                        category: category,
                        timestamp: DateTime.now(),
                      );
                      
                      setState(() {
                        widget.plan.realizedExpenses.add(newExpense);
                      });

                      // Persist
                      if (widget.planId != null) {
                        await TripCacheService.updateSavedPlan(widget.planId!, widget.plan);
                      } else {
                        // For non-saved active plan, we might update a 'volatile' cache if needed
                      }

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("ADD TO TRACKER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.sigiriyaOchre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget = _totalSpent > _budget;

    return Scaffold(
      backgroundColor: AppTheme.darkSurface,
      appBar: AppBar(
        title: const Text("Budget Hub"),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addExpense),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Visualization Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(opacity: 0.05),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140, height: 140,
                        child: CircularProgressIndicator(
                          value: _percentUsed,
                          strokeWidth: 12,
                          backgroundColor: Colors.white10,
                          color: isOverBudget ? Colors.redAccent : AppTheme.sigiriyaOchre,
                        ),
                      ),
                      Column(
                        children: [
                          Text("${(_percentUsed * 100).toInt()}%", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text("USED", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem("PLAN", _currencyFormat.format(_budget), Colors.white70),
                      _statItem("SPENT", _currencyFormat.format(_totalSpent), isOverBudget ? Colors.redAccent : AppTheme.sigiriyaOchre),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Expenses Log", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("${widget.plan.realizedExpenses.length} items", style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.plan.realizedExpenses.isEmpty)
              _buildEmptyState()
            else
              ...widget.plan.realizedExpenses.reversed.map((e) => _buildExpenseItem(e)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text("No expenses logged yet.", style: TextStyle(color: Colors.white24)),
          const SizedBox(height: 8),
          TextButton(onPressed: _addExpense, child: const Text("Log your first expense", style: TextStyle(color: AppTheme.sigiriyaOchre))),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(opacity: 0.03),
      child: Row(
        children: [
          _categoryIcon(e.category),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM dd, HH:mm').format(e.timestamp), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text(_currencyFormat.format(e.amountLkr), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _categoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'food': icon = Icons.restaurant; color = Colors.orangeAccent; break;
      case 'transport': icon = Icons.directions_car; color = Colors.blueAccent; break;
      case 'tickets': icon = Icons.confirmation_number; color = Colors.purpleAccent; break;
      default: icon = Icons.shopping_bag; color = Colors.tealAccent;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
