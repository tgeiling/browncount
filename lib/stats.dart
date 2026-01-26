// stats.dart - Brutalist Style
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'provider.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // Rating Colors - Brutalist palette
  static const Color colorTerrible = Color(0xFF5282C5);
  static const Color colorBad = Color(0xFF77AD52);
  static const Color colorOkay = Color(0xFFEDDB75);
  static const Color colorGood = Color(0xFFE8A64F);
  static const Color colorAmazing = Color(0xFFEC6152);

  Map<String, DayData> _dayDataMap = {};
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showShitCountColors = false;

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDayData();
  }

  Future<void> _loadDayData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    Map<String, DayData> tempMap = {};

    for (String key in keys) {
      if (key.startsWith('day_')) {
        final dateString = key.substring(4);
        final dataString = prefs.getString(key);
        if (dataString != null) {
          final parts = dataString.split('|');
          if (parts.length >= 2) {
            tempMap[dateString] = DayData(
              hasShit: parts[0] == '1',
              rating: int.tryParse(parts[1]) ?? -1,
              shitTime: parts.length > 2 ? parts[2] : '',
              ratingTime: parts.length > 3 ? parts[3] : '',
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _dayDataMap = tempMap;
      });
    }
  }

  Color _getColorForDay(DayData? data) {
    if (_showShitCountColors) {
      return _getShitCountColor(data);
    }

    if (data == null || (!data.hasShit && data.rating == -1)) {
      return Colors.grey[300]!;
    }

    if (data.hasShit && data.rating == -1) {
      return Colors.brown[300]!;
    }

    switch (data.rating) {
      case 0:
        return colorTerrible;
      case 1:
        return colorBad;
      case 2:
        return colorOkay;
      case 3:
        return colorGood;
      case 4:
        return colorAmazing;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getShitCountColor(DayData? data) {
    if (data == null || !data.hasShit) {
      return Colors.grey[300]!;
    }
    return const Color(0xFFD4A574);
  }

  void _showDayDetailsDialog(String dateString, DayData? dayData) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final details = await provider.getDayDetails(dateString);

    if (!mounted) return;

    bool hasShit = details?['hasShit'] ?? false;
    int rating = details?['rating'] ?? -1;
    String shitTime = details?['shitTime'] ?? '';
    String ratingTime = details?['ratingTime'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 4),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 3),
                        ),
                      ),
                      child: Text(
                        dateString,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shit Status
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shit:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Switch(
                                  value: hasShit,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      hasShit = value;
                                    });
                                  },
                                  activeColor: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          if (hasShit && shitTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 8),
                              child: Text(
                                'Time: ${_formatTime(shitTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Rating
                          const Text(
                            'Rating:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rating buttons
                          _buildDialogRatingButton(
                            'TERRIBLE',
                            0,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogRatingButton(
                            'BAD',
                            1,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogRatingButton(
                            'OKAY',
                            2,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogRatingButton(
                            'GOOD',
                            3,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogRatingButton(
                            'AMAZING',
                            4,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogRatingButton(
                            'NONE',
                            -1,
                            rating,
                            setDialogState,
                            (val) => rating = val,
                          ),
                          if (rating != -1 && ratingTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Time: ${_formatTime(ratingTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.black, width: 4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                            child: TextButton(
                              onPressed: () async {
                                await provider.updateDayData(
                                  dateString,
                                  hasShit,
                                  rating,
                                );
                                await _loadDayData();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: const Text(
                                'SAVE',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogRatingButton(
    String label,
    int value,
    int currentRating,
    StateSetter setDialogState,
    Function(int) onUpdate,
  ) {
    final isSelected = currentRating == value;
    Color buttonColor;

    switch (value) {
      case 0:
        buttonColor = colorTerrible;
        break;
      case 1:
        buttonColor = colorBad;
        break;
      case 2:
        buttonColor = colorOkay;
        break;
      case 3:
        buttonColor = colorGood;
        break;
      case 4:
        buttonColor = colorAmazing;
        break;
      default:
        buttonColor = Colors.grey[300]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonColor,
        border: Border.all(color: Colors.black, width: isSelected ? 4 : 3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setDialogState(() {
              onUpdate(value);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildMonthSelector(),
              const SizedBox(height: 24),

              // Day headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                        (day) => Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Calendar Grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday) {
                      return const SizedBox.shrink();
                    }

                    final day = index - firstWeekday + 1;
                    final dateString = '$_selectedYear-$_selectedMonth-$day';
                    final dayData = _dayDataMap[dateString];

                    return GestureDetector(
                      onTap: () => _showDayDetailsDialog(dateString, dayData),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForDay(dayData),
                          border: Border.all(color: Colors.black, width: 4),
                        ),
                        child: Center(
                          child: dayData != null && dayData.rating != -1
                              ? Text(
                                  _getRatingLabel(dayData.rating),
                                  style: GoogleFonts.boldonse(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildLegend(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        // Toggle button at bottom right
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showShitCountColors = !_showShitCountColors;
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  child: Icon(
                    _showShitCountColors
                        ? Icons.emoji_emotions
                        : Icons.color_lens,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.black, width: 4),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 1) {
                      _selectedMonth = 12;
                      _selectedYear--;
                    } else {
                      _selectedMonth--;
                    }
                  });
                },
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_getMonthName(_selectedMonth)} $_selectedYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black, width: 4)),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 24),
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                },
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (_showShitCountColors) ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.grey[300]!, 'No shit'),
                _buildLegendItem(const Color(0xFFD4A574), 'Shit 1'),
                _buildLegendItem(const Color(0xFFB08968), 'Shits 2'),
                _buildLegendItem(const Color(0xFF8B7355), 'Shits 3'),
                _buildLegendItem(const Color(0xFF5D4E37), 'Shits 4+'),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.grey[300]!, 'No data'),
                _buildLegendItem(Colors.brown[300]!, 'Shit only'),
                _buildLegendItem(colorTerrible, ":C Terrible"),
                _buildLegendItem(colorBad, ':( Bad'),
                _buildLegendItem(colorOkay, ':| Okay'),
                _buildLegendItem(colorGood, ':) Good'),
                _buildLegendItem(colorAmazing, ':D Amazing'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 0:
        return ":C";
      case 1:
        return ':(';
      case 2:
        return ':|';
      case 3:
        return ':)';
      case 4:
        return ':D';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'STATS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Container(color: Colors.black, height: 4),
            ),
          ),
          body: _buildMonthView(),
        );
      },
    );
  }
}

class DayData {
  final bool hasShit;
  final int rating;
  final String shitTime;
  final String ratingTime;

  DayData({
    required this.hasShit,
    required this.rating,
    this.shitTime = '',
    this.ratingTime = '',
  });
}
