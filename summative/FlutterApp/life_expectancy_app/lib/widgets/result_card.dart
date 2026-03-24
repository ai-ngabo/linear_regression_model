import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ResultState { initial, success, error }

class ResultCard extends StatelessWidget {
  final ResultState state;
  final double? prediction;
  final String? errorMessage;

  const ResultCard({
    super.key,
    required this.state,
    this.prediction,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    switch (state) {
      case ResultState.initial:
        return Card(
          key: const ValueKey('initial'),
          color: Colors.grey.shade100,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Your prediction will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case ResultState.success:
        return Card(
          key: const ValueKey('success'),
          color: Colors.teal.shade50,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.teal.shade600, size: 36),
                const SizedBox(height: 12),
                Text(
                  '${prediction!.toStringAsFixed(1)} years',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Predicted Life Expectancy at Birth',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.teal.shade400,
                  ),
                ),
              ],
            ),
          ),
        );

      case ResultState.error:
        return Card(
          key: const ValueKey('error'),
          color: Colors.red.shade50,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage ?? 'An error occurred',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}