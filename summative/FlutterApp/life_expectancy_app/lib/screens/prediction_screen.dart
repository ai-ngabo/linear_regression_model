import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/result_card.dart';

class _FieldDef {
  final String key;
  final String label;
  final String subtitle;
  final String hint;
  final IconData icon;
  final double min;
  final double max;
  final bool isInt;

  const _FieldDef({
    required this.key,
    required this.label,
    required this.subtitle,
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

  // Field definitions
  static const _healthcareFields = [
    _FieldDef(
      key: 'Adult_Mortality',
      label: 'Adult Mortality Rate',
      subtitle: 'Deaths per 1,000 adults',
      hint: 'e.g. 150',
      icon: Icons.person_off_outlined,
      min: 1,
      max: 723,
    ),
    _FieldDef(
      key: 'Hepatitis_B',
      label: 'Hepatitis B Coverage',
      subtitle: 'Immunization among 1-year-olds (%)',
      hint: 'e.g. 78',
      icon: Icons.vaccines_outlined,
      min: 1,
      max: 99,
    ),
    _FieldDef(
      key: 'Measles',
      label: 'Measles Cases',
      subtitle: 'Reported cases per 1,000 people',
      hint: 'e.g. 320',
      icon: Icons.bug_report_outlined,
      min: 0,
      max: 212183,
      isInt: true,
    ),
    _FieldDef(
      key: 'Polio',
      label: 'Polio Coverage',
      subtitle: 'Immunization among 1-year-olds (%)',
      hint: 'e.g. 85',
      icon: Icons.medical_services_outlined,
      min: 3,
      max: 99,
    ),
    _FieldDef(
      key: 'Diphtheria',
      label: 'DTP3 Coverage',
      subtitle: 'Diphtheria immunization among 1-year-olds (%)',
      hint: 'e.g. 90',
      icon: Icons.healing_outlined,
      min: 2,
      max: 99,
    ),
    _FieldDef(
      key: 'HIV_AIDS',
      label: 'HIV/AIDS Deaths',
      subtitle: 'Per 1,000 live births (age 0-4)',
      hint: 'e.g. 0.5',
      icon: Icons.coronavirus_outlined,
      min: 0.1,
      max: 50.6,
    ),
  ];

  static const _lifestyleFields = [
    _FieldDef(
      key: 'Alcohol',
      label: 'Alcohol Consumption',
      subtitle: 'Litres per person per year',
      hint: 'e.g. 4.5',
      icon: Icons.local_bar_outlined,
      min: 0,
      max: 18,
    ),
    _FieldDef(
      key: 'BMI',
      label: 'Average BMI',
      subtitle: 'Body Mass Index of entire population',
      hint: 'e.g. 32',
      icon: Icons.monitor_weight_outlined,
      min: 1,
      max: 88,
    ),
    _FieldDef(
      key: 'Thinness_1_19',
      label: 'Thinness (Age 10-19)',
      subtitle: 'Prevalence among adolescents (%)',
      hint: 'e.g. 5.3',
      icon: Icons.accessibility_new_outlined,
      min: 0.1,
      max: 27.7,
    ),
    _FieldDef(
      key: 'Thinness_5_9',
      label: 'Thinness (Age 5-9)',
      subtitle: 'Prevalence among children (%)',
      hint: 'e.g. 6.1',
      icon: Icons.child_care_outlined,
      min: 0.1,
      max: 28.6,
    ),
  ];

  static const _economicFields = [
    _FieldDef(
      key: 'GDP',
      label: 'GDP per Capita',
      subtitle: 'Gross Domestic Product in USD',
      hint: 'e.g. 12500',
      icon: Icons.attach_money_outlined,
      min: 1,
      max: 119173,
    ),
    _FieldDef(
      key: 'Pct_Expenditure',
      label: 'Health Expenditure',
      subtitle: '% of GDP per capita spent on health',
      hint: 'e.g. 73.5',
      icon: Icons.account_balance_outlined,
      min: 0,
      max: 19480,
    ),
    _FieldDef(
      key: 'Total_Exp',
      label: 'Gov. Health Spending',
      subtitle: '% of total government expenditure',
      hint: 'e.g. 7.2',
      icon: Icons.pie_chart_outline,
      min: 0,
      max: 18,
    ),
    _FieldDef(
      key: 'Income_Composition',
      label: 'Income Composition (HDI)',
      subtitle: 'Human Development Index (0 to 1)',
      hint: 'e.g. 0.68',
      icon: Icons.trending_up_outlined,
      min: 0,
      max: 0.948,
    ),
  ];

  static const _demographicFields = [
    _FieldDef(
      key: 'Population',
      label: 'Population',
      subtitle: 'Total country population',
      hint: 'e.g. 45000000',
      icon: Icons.groups_outlined,
      min: 34,
      max: 1293859294,
    ),
    _FieldDef(
      key: 'Under5_Deaths',
      label: 'Under-5 Deaths',
      subtitle: 'Per 1,000 population',
      hint: 'e.g. 30',
      icon: Icons.child_friendly_outlined,
      min: 0,
      max: 2500,
      isInt: true,
    ),
    _FieldDef(
      key: 'Schooling',
      label: 'Years of Schooling',
      subtitle: 'Mean years of education',
      hint: 'e.g. 10.5',
      icon: Icons.school_outlined,
      min: 0,
      max: 20.7,
    ),
  ];

  static const _allGroups = {
    'Healthcare': _healthcareFields,
    'Lifestyle': _lifestyleFields,
    'Economic': _economicFields,
    'Demographic': _demographicFields,
  };

  static const _groupIcons = {
    'Healthcare': Icons.local_hospital_outlined,
    'Lifestyle': Icons.fitness_center_outlined,
    'Economic': Icons.show_chart_outlined,
    'Demographic': Icons.people_outline,
  };

  // Controllers
  late final Map<String, TextEditingController> _controllers;
  final _countryController = TextEditingController();
  int _statusDeveloping = 1;
  String? _countryName;

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
    _countryController.dispose();
    super.dispose();
  }

  String? _validateField(_FieldDef field, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '${field.label} is required';
    }
    final num? parsed =
        field.isInt ? int.tryParse(value.trim()) : double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < field.min || parsed > field.max) {
      return 'Range: ${field.min} - ${field.max}';
    }
    return null;
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
        _countryName = _countryController.text.trim();
        _resultState = ResultState.success;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _resultState = ResultState.error;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // UI Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                _buildCountryField(),
                const SizedBox(height: 20),
                ..._allGroups.entries.map((group) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildGroupCard(
                        group.key,
                        _groupIcons[group.key]!,
                        group.value,
                      ),
                    )),
                _buildStatusCard(),
                const SizedBox(height: 28),
                _buildPredictButton(),
                const SizedBox(height: 20),
                ResultCard(
                  state: _resultState,
                  prediction: _prediction,
                  countryName: _countryName,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Life Expectancy Predictor',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Backed by WHO & World Bank Research Data',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCountryField() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.public_outlined,
                      color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Country',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'Which country are you researching?',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextFormField(
              controller: _countryController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a country name';
                }
                return null;
              },
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Country Name',
                hintText: 'e.g. Brazil',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade400),
                labelStyle: GoogleFonts.poppins(
                    fontSize: 13.5, color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: Colors.teal.shade400, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.teal.shade400, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade300),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(
      String title, IconData icon, List<_FieldDef> fields) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header inside the card
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((f) => _buildField(f)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(_FieldDef field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle / description above the field
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              field.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextFormField(
            controller: _controllers[field.key],
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _validateField(field, v),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400),
              labelStyle: GoogleFonts.poppins(
                  fontSize: 13.5, color: Colors.grey.shade600),
              prefixIcon: Icon(field.icon, color: Colors.teal.shade400, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.flag_outlined,
                      color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Country Status',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'Development classification of the country',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _statusDeveloping,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.teal.shade400),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade800),
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
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade400]
              : [Colors.teal.shade600, Colors.teal.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Predict Life Expectancy',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}