import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ResultState { initial, success, error }

class ResultCard extends StatelessWidget {
  final ResultState state;
  final double? prediction;
  final String? countryName;
  final String? errorMessage;

  const ResultCard({
    super.key,
    required this.state,
    this.prediction,
    this.countryName,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    switch (state) {
      case ResultState.initial:
        return Container(
          key: const ValueKey('initial'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined,
                  color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Your prediction will appear here',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        );

      case ResultState.success:
        return Container(
          key: const ValueKey('success'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.teal.shade700, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                '${prediction!.toStringAsFixed(1)} years',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.teal.shade700,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Based on the data provided, life expectancy in '),
                      TextSpan(
                        text: countryName ?? 'this country',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' is '),
                      TextSpan(
                        text: '${prediction!.toStringAsFixed(1)} years',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );

      case ResultState.error:
        return Container(
          key: const ValueKey('error'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.error_outline,
                    color: Colors.red.shade400, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  errorMessage ?? 'An error occurred',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}