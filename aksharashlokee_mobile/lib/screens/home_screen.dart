import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../models/shloka.dart';
import '../services/local_shloka_service.dart';
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF9FAFB),
              const Color(0xFFE8F4FD),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFF007AFF),
                const Color(0xFF5856D6),
              ],
            ).createShader(bounds),
            child: Text(
              'अक्षरश्लोकी',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Color(0xFF007AFF),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Akshara Selector
                Icon(
                  CupertinoIcons.circle_grid_3x3_fill,
                  color: const Color(0xFF007AFF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAkshara,
                    hint: const Text('अक्षराणि'),
                    underline: const SizedBox(),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('अक्षराणि'),
                      ),
                      ..._aksharas.map((akshara) {
                        return DropdownMenuItem(
                          value: akshara,
                          child: Text(akshara),
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
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
            color: Color(0xFF007AFF),
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
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF3CD),
                const Color(0xFFFFE69C),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFC107).withValues(alpha: 0.3),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                '॥ मङ्गलम् ॥',
                style: TextStyle(
                  fontSize: _fontSize + 4,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'वागर्थाविव संपृक्तौ वागर्थप्रतिपत्तये।',
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'जगतः पितरौ वन्दे पार्वतीपरमेश्वरौ ।।',
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
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
              color: const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
                  onPressed: _resetToInitialState,
                ),
                Expanded(
                  child: Text(
                    _isSearching
                        ? 'Search Results (${_shlokas.length})'
                        : 'Shlokas for "$_selectedAkshara"',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
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
        child: Stack(
          children: [
            // Top gradient bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF007AFF),
                      const Color(0xFF5856D6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shloka content with line breaks
                  Text(
                    _formatShlokaContent(shloka.content),
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.8,
                      color: const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 16),

                  // Reference
                  Text(
                    '— ${shloka.reference}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
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
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
