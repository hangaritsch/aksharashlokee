import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/shloka.dart';
import '../services/local_shloka_service.dart';
import '../widgets/app_logo.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<String> _aksharas = [];
  String? _selectedAkshara;
  List<Shloka> _shlokas = [];
  bool _isLoading = false;
  String? _error;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showSearchBar = false;
  bool _showInitialShloka = true;
  double _fontSize = 18.0;
  bool _showFontPanel = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAksharas();
    _loadSavedFontSize();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadSavedFontSize() {
    // In a real app, load from SharedPreferences
    setState(() {
      _fontSize = 18.0;
    });
  }

  Future<void> _loadAksharas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aksharas = await LocalShlokaService.getAksharas();
      setState(() {
        _aksharas = aksharas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadShlokas(String akshara) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedAkshara = akshara;
      _isSearching = false;
      _searchController.clear();
      _showSearchBar = false;
      _showInitialShloka = false;
    });

    try {
      final shlokasList = await LocalShlokaService.getShlokasByAkshara(akshara);
      setState(() {
        _shlokas = shlokasList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchShlokas(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSearching = true;
      _showInitialShloka = false;
    });

    try {
      final shlokasList = await LocalShlokaService.searchShlokas(query);
      setState(() {
        _shlokas = shlokasList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetToInitialState() {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedAkshara = null;
      _shlokas = [];
      _isSearching = false;
      _showSearchBar = false;
      _searchController.clear();
      _showInitialShloka = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E3), // Light Parchment
              Color(0xFFFFF0B2), // Soft Ochre
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),

                  // Control Panel
                  SliverToBoxAdapter(
                    child: _buildControlPanel(),
                  ),

                  // Initial Shloka
                  if (_showInitialShloka)
                    SliverToBoxAdapter(
                      child: _buildInitialShloka(),
                    ),

                  // Content Area
                  if (_selectedAkshara == null &&
                      !_isSearching &&
                      !_showInitialShloka)
                    _buildAksharasGrid()
                  else if (_selectedAkshara != null || _isSearching)
                    _buildShlokasList(),
                ],
              ),

              // Font Size Controls
              _buildFontControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 60),
              const SizedBox(width: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF800000), // Maroon
                    Color(0xFFD35400), // Saffron
                  ],
                ).createShader(bounds),
                child: Text(
                  'अक्षरश्लोकी',
                  style: GoogleFonts.tiroDevanagariSanskrit(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFD35400).withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Search Button
                      _buildSearchButton(),

                      if (_showSearchBar) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSearchField(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Info Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD35400).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Color(0xFF800000),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD35400).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFF800000),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Akshara Selector
                const Icon(
                  CupertinoIcons.circle_grid_3x3_fill,
                  color: Color(0xFF800000),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD35400).withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAkshara,
                      menuMaxHeight: 350,
                      hint: Text(
                        'अ',
                        style: GoogleFonts.tiroDevanagariSanskrit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF800000),
                        ),
                      ),
                      dropdownColor: const Color(0xFFFFF9E3),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD35400)),
                      isDense: true,
                      alignment: Alignment.centerLeft,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'अक्षराणि',
                              style: GoogleFonts.mukta(fontWeight: FontWeight.w600, color: const Color(0xFF800000)),
                            ),
                          ),
                        ),
                        ..._aksharas.map((akshara) {
                          return DropdownMenuItem(
                            value: akshara,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                akshara,
                                style: GoogleFonts.tiroDevanagariSanskrit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D1410),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          _resetToInitialState();
                        } else {
                          _loadShlokas(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSearchBar = !_showSearchBar;
          if (_showSearchBar) {
            _selectedAkshara = null;
            _shlokas = [];
            _isSearching = false;
            _showInitialShloka = false;
            _error = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _searchFocusNode.requestFocus();
              }
            });
          } else {
            _searchController.clear();
            _resetToInitialState();
          }
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF800000), // Changed to Maroon
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF800000).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _showSearchBar ? CupertinoIcons.xmark : CupertinoIcons.search,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (value) {
        final query = value.trim();
        if (query.isEmpty) {
          setState(() {
            _isSearching = false;
            _shlokas = [];
            _showInitialShloka = false;
            _error = null;
          });
        } else {
          _searchShlokas(query);
        }
      },
      onSubmitted: (value) {
        final query = value.trim();
        if (query.isNotEmpty) {
          _searchShlokas(query);
        }
      },
      decoration: InputDecoration(
        hintText: 'श्लोकं अन्विष्यन्तु',
        hintStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 15,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 8, right: 4),
          child: Icon(
            CupertinoIcons.search,
            color: Color(0xFFD35400), // Changed to Saffron
            size: 18,
          ),
        ),
        suffixIcon: _searchController.text.trim().isNotEmpty
            ? IconButton(
                icon: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false;
                    _shlokas = [];
                    _showInitialShloka = false;
                    _error = null;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF800000), width: 1.5), // Changed to Maroon
        ),
      ),
    );
  }

  Widget _buildInitialShloka() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E3), // Solid Parchment
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD35400).withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF800000).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                '॥ मङ्गलम् ॥',
                style: GoogleFonts.tiroDevanagariSanskrit(
                  fontSize: _fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF800000),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'वागर्थाविव संपृक्तौ वागर्थप्रतिपत्तये।',
                style: GoogleFonts.tiroDevanagariSanskrit(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D1B13),
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'जगतः पितरौ वन्दे पार्वतीपरमेश्वरौ ।।',
                style: GoogleFonts.tiroDevanagariSanskrit(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D1B13),
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAksharasGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: _isLoading
          ? SliverToBoxAdapter(
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          : _error != null
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          onPressed: _loadAksharas,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final akshara = _aksharas[index];
                      return _buildAksharaCard(akshara, index);
                    },
                    childCount: _aksharas.length,
                  ),
                ),
    );
  }

  Widget _buildAksharaCard(String akshara, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 20)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _loadShlokas(akshara),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              akshara,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShlokasList() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Header
        if (_selectedAkshara != null || _isSearching)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD35400).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD35400).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(CupertinoIcons.back, color: Color(0xFF800000)),
                  onPressed: _resetToInitialState,
                ),
                Expanded(
                  child: Text(
                    _isSearching
                        ? 'Search Results (${_shlokas.length})'
                        : 'Shlokas for "$_selectedAkshara"',
                    style: GoogleFonts.tiroDevanagariSanskrit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF800000),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
          ),

        // No results message
        if (!_isLoading && _shlokas.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF9500).withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              'परिणामः न लभ्यते।',
              style: TextStyle(
                color: Color(0xFFFF9500),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Shlokas list
        if (!_isLoading && _shlokas.isNotEmpty)
          ..._shlokas.asMap().entries.map((entry) {
            final index = entry.key;
            final shloka = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildShlokaCard(shloka, index),
            );
          }),

        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildShlokaCard(Shloka shloka, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD35400).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF800000).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative vertical scroll bars
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFD35400).withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFD35400).withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shloka content
                  Text(
                    _formatShlokaContent(shloka.content),
                    style: GoogleFonts.tiroDevanagariSanskrit(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold, // Bolder for clarity
                      height: 1.8,
                      color: const Color(0xFF2D1410), // Deep, dark reddish brown
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Ornamental divider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1.5, width: 50, color: const Color(0xFFD35400).withOpacity(0.4)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.brightness_high, size: 16, color: Color(0xFF800000)),
                      ),
                      Container(height: 1.5, width: 50, color: const Color(0xFFD35400).withOpacity(0.4)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reference
                  Text(
                    '— ${shloka.reference}',
                    style: GoogleFonts.mukta(
                      color: const Color(0xFF800000),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShlokaContent(String content) {
    // Format shloka with proper line breaks
    return content
        .replaceAll('।।', '।।\n')
        .replaceAll(RegExp(r'।(?!।)'), '।\n')
        .trim();
  }

  Widget _buildFontControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showFontPanel)
            Container(
              width: 220,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    activeColor: const Color(0xFF007AFF),
                    label: '${_fontSize.round()}px',
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                  Text(
                    '${_fontSize.round()}px',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFontPanel = !_showFontPanel;
              });
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF800000), // Changed to Maroon
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF800000).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.textformat_size,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
