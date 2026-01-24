// start.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool _hasShownStreakDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (provider.isInitialized && !_hasShownStreakDialog) {
      final streakInfo = provider.getStreakLostInfo();

      if (streakInfo['hasLost']) {
        _hasShownStreakDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStreakLostDialog(
            streakInfo['ratingLost'],
            streakInfo['shitLost'],
          );
        });
      }
    }
  }

  void _showStreakLostDialog(bool ratingLost, bool shitLost) {
    String message = '';
    if (ratingLost && shitLost) {
      message =
          'You missed giving a rating and taking a shit yesterday. Both streaks have been reset to 0.';
    } else if (ratingLost) {
      message =
          'You missed giving a rating yesterday. Your rating streak has been reset to 0.';
    } else if (shitLost) {
      message =
          'You missed taking a shit yesterday. Your shit streak has been reset to 0.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFBF8F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Streak Lost!',
            style: TextStyle(
              color: Color(0xFF5D4E37),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Color(0xFF5D4E37)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFBF8F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'RATE THE DAY',
            style: TextStyle(
              color: Color(0xFF5D4E37),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 11,
              itemBuilder: (context, index) {
                return Material(
                  color: const Color(0xFF5D4E37),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () async {
                      await context.read<AppProvider>().setRating(index);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F3),
          body: SafeArea(
            child: Column(
              children: [
                // Stats Row
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge(
                        'RATING\nStreak',
                        provider.ratingStreak,
                        const Color(0xFFD4A574),
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        'SHIT\nStreak',
                        provider.shitStreak,
                        const Color(0xFFB08968),
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        'TODAY\nRating',
                        provider.todaysRating == -1 ? 0 : provider.todaysRating,
                        const Color(0xFF8B7355),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Total Count Label
                const Text(
                  'TOTAL COUNT',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA0826D),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                // Main Counter
                Expanded(
                  child: Center(
                    child: Text(
                      '${provider.counter}',
                      style: const TextStyle(
                        fontSize: 140,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4E37),
                        height: 1,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Color(0x0D000000),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Material(
                            color: const Color(0xFF5D4E37),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => provider.incrementCounter(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 20,
                                ),
                                child: const Center(
                                  child: Text(
                                    'I have taken a shit',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Material(
                            color: const Color(0xFFA0826D),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _showRatingDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 20,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Rate the Day',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
