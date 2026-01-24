// stats.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, DayData> _dayDataMap = {};
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showShitCountColors =
      false; // false = rating colors, true = shit count colors

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

    if (data.rating >= 0 && data.rating <= 3) {
      return Colors.red[400]!;
    } else if (data.rating >= 4 && data.rating <= 6) {
      return Colors.orange[400]!;
    } else if (data.rating >= 7 && data.rating <= 8) {
      return Colors.lightGreen[400]!;
    } else if (data.rating >= 9) {
      return Colors.green[600]!;
    }

    return Colors.grey[300]!;
  }

  Color _getShitCountColor(DayData? data) {
    if (data == null || !data.hasShit) {
      return Colors.grey[300]!;
    }

    // Count shits for this day - for now, we'll use intensity based on having a shit
    // Since we only track 1 shit per day in current implementation,
    // we'll create 4 shades: no data, has shit (light to dark brown based on rating as proxy)
    // If you want actual shit count per day, the data structure needs to be modified

    // For now, use 4 brown shades based on combination of having shit and rating
    if (data.rating == -1) {
      // Shit only, no rating - lightest brown
      return const Color(0xFFD4A574); // Light brown
    } else if (data.rating >= 0 && data.rating <= 3) {
      return const Color(0xFFB08968); // Medium-light brown
    } else if (data.rating >= 4 && data.rating <= 7) {
      return const Color(0xFF8B7355); // Medium brown
    } else {
      return const Color(0xFF5D4E37); // Dark brown
    }
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
              backgroundColor: const Color(0xFFFBF8F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        dateString,
                        style: const TextStyle(
                          color: Color(0xFF5D4E37),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shit Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shit:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4E37),
                                ),
                              ),
                              Switch(
                                value: hasShit,
                                onChanged: (value) {
                                  setDialogState(() {
                                    hasShit = value;
                                  });
                                },
                                activeColor: const Color(0xFF5D4E37),
                              ),
                            ],
                          ),
                          if (hasShit && shitTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                'Time: ${_formatTime(shitTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0826D),
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
                              color: Color(0xFF5D4E37),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rating Grid - Fixed height
                          SizedBox(
                            height: 180,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 1.2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: 11,
                              itemBuilder: (context, index) {
                                final isSelected = rating == index;
                                return Material(
                                  color: isSelected
                                      ? const Color(0xFF5D4E37)
                                      : const Color(0xFFE8DCC8),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        rating = index;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Center(
                                      child: Text(
                                        '$index',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF5D4E37),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (rating != -1 && ratingTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Time: ${_formatTime(ratingTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0826D),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFA0826D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async {
                              await provider.updateDayData(
                                dateString,
                                hasShit,
                                rating,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                _loadDayData();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF5D4E37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Widget _buildMonthView() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Stack(
      children: [
        Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
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
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[400]!, width: 1),
                      ),
                      child: Center(
                        child: dayData != null && dayData.rating != -1
                            ? Text(
                                '${dayData.rating}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildLegend(),
          ],
        ),
        // Toggle button at bottom right
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showShitCountColors = !_showShitCountColors;
              });
            },
            backgroundColor: const Color(0xFF5D4E37),
            child: Icon(
              _showShitCountColors ? Icons.emoji_emotions : Icons.color_lens,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
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
          ),
          Text(
            '${_getMonthName(_selectedMonth)} $_selectedYear',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
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
          ),
        ],
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_showShitCountColors) ...[
            // Shit count color legend
            Row(
              children: [
                _buildLegendItem(Colors.grey[300]!, 'No shit'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFFD4A574), 'Shit only'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(const Color(0xFFB08968), 'Shit + rating 0-3'),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFF8B7355), 'Shit + rating 4-7'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(const Color(0xFF5D4E37), 'Shit + rating 8+'),
              ],
            ),
          ] else ...[
            // Rating color legend
            Row(
              children: [
                _buildLegendItem(Colors.grey[300]!, 'No data'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.brown[300]!, 'Shit only'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.red[400]!, 'Bad (0-3)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange[400]!, 'Okay (4-6)'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.lightGreen[400]!, 'Good (7-8)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green[600]!, 'Great (9-10)'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F3),
          appBar: AppBar(
            title: const Text('Stats'),
            backgroundColor: const Color(0xFFE8DCC8),
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
