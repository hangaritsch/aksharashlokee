import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/shloka.dart';
import '../services/local_shloka_service.dart';
import '../utils/shloka_formatter.dart';
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
  List<String> _granthas = [];
  String? _selectedAkshara;
  String? _selectedGrantha;
  List<Shloka> _shlokas = [];
  bool _isLoading = false;
  String? _error;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showSearchBar = false;
  bool _showInitialShloka = true;
  String _devanagariSearchHint = '';
  List<String> _wordSuggestions = [];
  double _fontSize = 18.0;
  bool _showFontPanel = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAksharasAndGranthas();
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
    setState(() {
      _fontSize = 18.0;
    });
  }

  Future<void> _loadAksharasAndGranthas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aksharas = await LocalShlokaService.getAksharas();
      final granthas = await LocalShlokaService.getGranthas();
      setState(() {
        _aksharas = aksharas;
        _granthas = granthas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _applyCombinedFilters() async {
    final query = _searchController.text.trim();
    final devanagariText = DevanagariTransliterater.transliterate(query);

    setState(() {
      _isLoading = true;
      _error = null;
      _isSearching = query.isNotEmpty || _selectedAkshara != null || _selectedGrantha != null;
      _devanagariSearchHint = (query.isNotEmpty && devanagariText != query) ? devanagariText : '';
      _showInitialShloka = false;
    });

    try {
      // Fetch combined filtered shlokas
      final shlokasList = await LocalShlokaService.getFilteredShlokas(
        akshara: _selectedAkshara,
        grantha: _selectedGrantha,
        query: query.isNotEmpty ? query : null,
        devanagariQuery: devanagariText.isNotEmpty ? devanagariText : null,
      );

      // Fetch word suggestions if user is searching in English/Devanagari
      List<String> suggestions = [];
      if (query.isNotEmpty) {
        suggestions = await LocalShlokaService.getSanskritWordSuggestions(
          devanagariText.isNotEmpty ? devanagariText : query,
        );
      }

      setState(() {
        _shlokas = shlokasList;
        _wordSuggestions = suggestions;
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
    _selectedAkshara = akshara;
    _applyCombinedFilters();
  }

  Future<void> _loadShlokasByGrantha(String grantha) async {
    _selectedGrantha = grantha;
    _applyCombinedFilters();
  }

  Future<void> _searchShlokas(String query) async {
    _applyCombinedFilters();
  }

  void _resetToInitialState() {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedAkshara = null;
      _selectedGrantha = null;
      _shlokas = [];
      _isSearching = false;
      _showSearchBar = false;
      _searchController.clear();
      _devanagariSearchHint = '';
      _wordSuggestions = [];
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD35400).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF800000).withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Floating Search Button & Animated Expandable Input
                    if (_showSearchBar) ...[
                      Expanded(
                        child: _buildSearchField(),
                      ),
                      const SizedBox(width: 8),
                      _buildSearchButton(),
                    ] else ...[
                      _buildSearchButton(),
                      const SizedBox(width: 10),

                      // Info Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD35400).withOpacity(0.3),
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
                      const SizedBox(width: 8),

                      // Privacy Button
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD35400).withOpacity(0.3),
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
                      const Spacer(),

                      // Akshara Selector
                      _buildAksharaSelector(),
                      const SizedBox(width: 8),

                      // Grantha Selector
                      _buildGranthaSelector(),
                    ],
                  ],
                ),

                // Active Filter Badges (Pills)
                if (_selectedAkshara != null || _selectedGrantha != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_selectedAkshara != null) ...[
                        Chip(
                          avatar: const Icon(CupertinoIcons.circle_grid_3x3_fill, size: 14, color: Colors.white),
                          label: Text(
                            'अक्षरम्: $_selectedAkshara',
                            style: GoogleFonts.tiroDevanagariSanskrit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF800000),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white70),
                          onDeleted: () {
                            setState(() {
                              _selectedAkshara = null;
                            });
                            _applyCombinedFilters();
                          },
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (_selectedGrantha != null) ...[
                        Chip(
                          avatar: const Icon(Icons.book, size: 14, color: Colors.white),
                          label: Text(
                            _selectedGrantha!.length > 12
                                ? '${_selectedGrantha!.substring(0, 12)}...'
                                : _selectedGrantha!,
                            style: GoogleFonts.tiroDevanagariSanskrit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFFD35400),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white70),
                          onDeleted: () {
                            setState(() {
                              _selectedGrantha = null;
                            });
                            _applyCombinedFilters();
                          },
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ],
                    ],
                  ),
                ],

                // Transliteration live hint chip & Interactive Sanskrit Suggestions
                if (_showSearchBar && (_devanagariSearchHint.isNotEmpty || _wordSuggestions.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD35400).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_devanagariSearchHint.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.g_translate, size: 16, color: Color(0xFFD35400)),
                                const SizedBox(width: 6),
                                Text(
                                  'देवनागरी (Devanagari): ',
                                  style: GoogleFonts.mukta(
                                    fontSize: 13,
                                    color: const Color(0xFF800000),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _devanagariSearchHint,
                                    style: GoogleFonts.tiroDevanagariSanskrit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D1410),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Tappable Sanskrit Auto-Suggestion Chips
                        if (_wordSuggestions.isNotEmpty) ...[
                          Text(
                            'सूचिताः शब्दाः (Suggested Words):',
                            style: GoogleFonts.mukta(
                              fontSize: 12,
                              color: const Color(0xFF800000),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _wordSuggestions.map((word) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: const Color(0xFFD35400).withOpacity(0.4)),
                                    label: Text(
                                      word,
                                      style: GoogleFonts.tiroDevanagariSanskrit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF800000),
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.text = word;
                                      _applyCombinedFilters();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAksharaSelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFFFFF9E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFFD35400).withOpacity(0.3)),
          ),
        ),
      ),
      child: PopupMenuButton<String?>(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120,
          maxHeight: 350,
        ),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == null) {
            _resetToInitialState();
          } else {
            _loadShlokas(value);
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String?>(
              value: null,
              height: 36,
              child: Text(
                'अक्षराणि',
                style: GoogleFonts.mukta(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF800000),
                  fontSize: 14,
                ),
              ),
            ),
            ..._aksharas.map((akshara) {
              return PopupMenuItem<String?>(
                value: akshara,
                height: 36,
                child: Text(
                  akshara,
                  style: GoogleFonts.tiroDevanagariSanskrit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1410),
                  ),
                ),
              );
            }),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD35400).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedAkshara ?? 'अक्षरम्',
                style: GoogleFonts.tiroDevanagariSanskrit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF800000),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, color: Color(0xFFD35400), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGranthaSelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFFFFF9E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFFD35400).withOpacity(0.3)),
          ),
        ),
      ),
      child: PopupMenuButton<String?>(
        constraints: const BoxConstraints(
          minWidth: 160,
          maxWidth: 240,
          maxHeight: 380,
        ),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == null) {
            _resetToInitialState();
          } else {
            _loadShlokasByGrantha(value);
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String?>(
              value: null,
              height: 36,
              child: Text(
                'सर्वे ग्रन्थाः',
                style: GoogleFonts.mukta(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF800000),
                  fontSize: 14,
                ),
              ),
            ),
            ..._granthas.map((grantha) {
              return PopupMenuItem<String?>(
                value: grantha,
                height: 40,
                child: Text(
                  grantha,
                  style: GoogleFonts.tiroDevanagariSanskrit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D1410),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD35400).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _selectedGrantha != null
                      ? (_selectedGrantha!.length > 8
                          ? '${_selectedGrantha!.substring(0, 8)}...'
                          : _selectedGrantha!)
                      : 'ग्रन्थाः',
                  style: GoogleFonts.tiroDevanagariSanskrit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800000),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, color: Color(0xFFD35400), size: 18),
            ],
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
            _selectedGrantha = null;
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
            _devanagariSearchHint = '';
            _resetToInitialState();
          }
        });
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF800000),
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
      style: GoogleFonts.tiroDevanagariSanskrit(
        color: const Color(0xFF2D1410), // High-visibility dark brown
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
      onChanged: (value) {
        final query = value.trim();
        if (query.isEmpty) {
          setState(() {
            _isSearching = false;
            _shlokas = [];
            _showInitialShloka = false;
            _devanagariSearchHint = '';
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
        hintText: 'श्लोकं / English अन्विष्यन्तु...',
        hintStyle: GoogleFonts.mukta(
          color: const Color(0xFF8E8E93),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFFFFDF5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD35400).withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD35400).withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF800000), width: 1.5),
        ),
        suffixIcon: _searchController.text.trim().isNotEmpty
            ? IconButton(
                icon: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: Color(0xFF800000),
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false;
                    _shlokas = [];
                    _devanagariSearchHint = '';
                  });
                },
              )
            : null,
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
                          onPressed: _loadAksharasAndGranthas,
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
    // Standardize shloka structure and line breaks automatically
    final cleaned = ShlokaFormatter.formatContent(content);
    return cleaned
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
