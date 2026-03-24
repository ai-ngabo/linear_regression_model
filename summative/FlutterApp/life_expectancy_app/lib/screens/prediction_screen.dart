import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/result_card.dart';

class _FieldDef {
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final double min;
  final double max;
  final bool isInt;

  const _FieldDef({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.min,
    required this.max,
    this.isInt = false,
  });
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  ResultState _resultState = ResultState.initial;
  double? _prediction;
  String? _errorMessage;

  // Grouped field definitions matching API's PredictionInput model
  static const _healthcareFields = [
    _FieldDef(
      key: 'Adult_Mortality',
      label: 'Adult Mortality',
      hint: 'e.g. 263 (per 1000 population)',
      icon: Icons.person,
      min: 1,
      max: 723,
    ),
    _FieldDef(
      key: 'Hepatitis_B',
      label: 'Hepatitis B Coverage (%)',
      hint: 'e.g. 65',
      icon: Icons.vaccines,
      min: 1,
      max: 99,
    ),
    _FieldDef(
      key: 'Measles',
      label: 'Measles Cases',
      hint: 'e.g. 1154 (per 1000)',
      icon: Icons.bug_report,
      min: 0,
      max: 212183,
      isInt: true,
    ),
    _FieldDef(
      key: 'Polio',
      label: 'Polio Coverage (%)',
      hint: 'e.g. 65',
      icon: Icons.medical_services,
      min: 3,
      max: 99,
    ),
    _FieldDef(
      key: 'Diphtheria',
      label: 'Diphtheria Coverage (%)',
      hint: 'e.g. 65',
      icon: Icons.healing,
      min: 2,
      max: 99,
    ),
    _FieldDef(
      key: 'HIV_AIDS',
      label: 'HIV/AIDS Deaths',
      hint: 'e.g. 0.1 (per 1000 births, 0-4 yrs)',
      icon: Icons.coronavirus,
      min: 0.1,
      max: 50.6,
    ),
  ];

  static const _lifestyleFields = [
    _FieldDef(
      key: 'Alcohol',
      label: 'Alcohol Consumption',
      hint: 'e.g. 0.01 (litres per capita)',
      icon: Icons.local_bar,
      min: 0,
      max: 18,
    ),
    _FieldDef(
      key: 'BMI',
      label: 'Average BMI',
      hint: 'e.g. 19.1',
      icon: Icons.monitor_weight,
      min: 1,
      max: 88,
    ),
    _FieldDef(
      key: 'Thinness_1_19',
      label: 'Thinness 1-19 yrs (%)',
      hint: 'e.g. 17.2',
      icon: Icons.accessibility_new,
      min: 0.1,
      max: 27.7,
    ),
    _FieldDef(
      key: 'Thinness_5_9',
      label: 'Thinness 5-9 yrs (%)',
      hint: 'e.g. 17.3',
      icon: Icons.child_care,
      min: 0.1,
      max: 28.6,
    ),
  ];

  static const _economicFields = [
    _FieldDef(
      key: 'GDP',
      label: 'GDP per Capita (USD)',
      hint: 'e.g. 584.26',
      icon: Icons.attach_money,
      min: 1,
      max: 119173,
    ),
    _FieldDef(
      key: 'Pct_Expenditure',
      label: 'Health Expenditure (% GDP)',
      hint: 'e.g. 71.28',
      icon: Icons.account_balance,
      min: 0,
      max: 19480,
    ),
    _FieldDef(
      key: 'Total_Exp',
      label: 'Total Health Expenditure (%)',
      hint: 'e.g. 8.16',
      icon: Icons.pie_chart,
      min: 0,
      max: 18,
    ),
    _FieldDef(
      key: 'Income_Composition',
      label: 'Income Composition (HDI)',
      hint: 'e.g. 0.479 (0 to 0.948)',
      icon: Icons.trending_up,
      min: 0,
      max: 0.948,
    ),
  ];

  static const _demographicFields = [
    _FieldDef(
      key: 'Population',
      label: 'Population',
      hint: 'e.g. 33736494',
      icon: Icons.groups,
      min: 34,
      max: 1293859294,
    ),
    _FieldDef(
      key: 'Under5_Deaths',
      label: 'Under-5 Deaths',
      hint: 'e.g. 83 (per 1000)',
      icon: Icons.child_friendly,
      min: 0,
      max: 2500,
      isInt: true,
    ),
    _FieldDef(
      key: 'Schooling',
      label: 'Schooling (years)',
      hint: 'e.g. 10.1',
      icon: Icons.school,
      min: 0,
      max: 20.7,
    ),
  ];

  static const _allGroups = {
    'Healthcare Indicators': _healthcareFields,
    'Lifestyle Indicators': _lifestyleFields,
    'Economic Indicators': _economicFields,
    'Demographic Indicators': _demographicFields,
  };

  // Controllers for all numeric fields
  late final Map<String, TextEditingController> _controllers;

  // Status dropdown
  int _statusDeveloping = 1;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final group in _allGroups.values) {
      for (final field in group) {
        _controllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateField(_FieldDef field, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${field.label} is required';
    }
    final num? parsed =
        field.isInt ? int.tryParse(value.trim()) : double.tryParse(value.trim());
    if (parsed == null) {
      return '${field.label} must be a valid number';
    }
    if (parsed < field.min || parsed > field.max) {
      return 'Range: ${field.min} – ${field.max}';
    }
    return null;
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final features = <String, dynamic>{};
      for (final group in _allGroups.values) {
        for (final field in group) {
          final text = _controllers[field.key]!.text.trim();
          features[field.key] =
              field.isInt ? int.parse(text) : double.parse(text);
        }
      }
      features['Status_Developing'] = _statusDeveloping;

      final result = await _apiService.predict(features);
      setState(() {
        _prediction = result;
        _resultState = ResultState.success;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _resultState = ResultState.error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                // Field groups
                ..._allGroups.entries.expand((group) => [
                      _buildSectionHeader(group.key),
                      const SizedBox(height: 8),
                      ...group.value.map(_buildField),
                      const SizedBox(height: 16),
                    ]),
                // Country status dropdown
                _buildSectionHeader('Country Status'),
                const SizedBox(height: 8),
                _buildStatusDropdown(),
                const SizedBox(height: 24),
                // Predict button
                _buildPredictButton(),
                const SizedBox(height: 20),
                // Result card
                ResultCard(
                  state: _resultState,
                  prediction: _prediction,
                  errorMessage: _errorMessage,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(Icons.health_and_safety, size: 48, color: Colors.teal.shade600),
        const SizedBox(height: 8),
        Text(
          'Life Expectancy Predictor',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Powered by World Bank Data',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade600,
        ),
      ),
    );
  }

  Widget _buildField(_FieldDef field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[field.key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) => _validateField(field, v),
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
          prefixIcon: Icon(field.icon, color: Colors.teal),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.flag, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _statusDeveloping,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Developing')),
                    DropdownMenuItem(value: 0, child: Text('Developed')),
                  ],
                  onChanged: (v) => setState(() => _statusDeveloping = v!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Predict Life Expectancy',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}