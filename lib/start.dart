// start.dart - Brutalist Style
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
  String _lastCheckedDate = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (provider.isInitialized && !_hasShownStreakDialog) {
      _checkStreakStatus(provider);
    }
  }

  void _checkStreakStatus(AppProvider provider) {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    // Only check once per day
    if (_lastCheckedDate == todayString) return;

    _lastCheckedDate = todayString;
    final streakInfo = provider.getStreakLostInfo();

    if (streakInfo['hasLost']) {
      _hasShownStreakDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStreakLostDialog(
          streakInfo['ratingLost'],
          streakInfo['brownLost'],
        );
      });
    }
  }

  void _showStreakLostDialog(bool ratingLost, bool brownLost) {
    String message = '';
    if (ratingLost && brownLost) {
      message =
          'You missed giving a rating and taking a brown yesterday. Both streaks have been reset to 0.';
    } else if (ratingLost) {
      message =
          'You missed giving a rating yesterday. Your rating streak has been reset to 0.';
    } else if (brownLost) {
      message =
          'You missed taking a brown yesterday. Your brown streak has been reset to 0.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(0),
          ),
          title: const Text(
            'STREAK LOST!',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(0),
          ),
          title: const Text(
            'RATE THE DAY',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRatingButton(context, DayRating.terrible),
                const SizedBox(height: 12),
                _buildRatingButton(context, DayRating.bad),
                const SizedBox(height: 12),
                _buildRatingButton(context, DayRating.okay),
                const SizedBox(height: 12),
                _buildRatingButton(context, DayRating.good),
                const SizedBox(height: 12),
                _buildRatingButton(context, DayRating.amazing),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.black, width: 4),
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
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingButton(BuildContext context, DayRating rating) {
    Color buttonColor;
    switch (rating) {
      case DayRating.terrible:
        buttonColor = const Color(0xFF5282C5);
        break;
      case DayRating.bad:
        buttonColor = const Color(0xFF77AD52);
        break;
      case DayRating.okay:
        buttonColor = const Color(0xFFEDDB75);
        break;
      case DayRating.good:
        buttonColor = const Color(0xFFE8A64F);
        break;
      case DayRating.amazing:
        buttonColor = const Color(0xFFEC6152);
        break;
      default:
        buttonColor = Colors.black;
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonColor,
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.read<AppProvider>().setRating(rating);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                rating.displayName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Check for day changes whenever the widget rebuilds
        if (provider.isInitialized) {
          _checkStreakStatus(provider);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Stats Row
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildStatBadge(
                          'RATING\nSTREAK',
                          provider.ratingStreak,
                          const Color(0xFFD4A574),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatBadge(
                          'BROWN\nSTREAK',
                          provider.brownStreak,
                          const Color(0xFFB08968),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatBadgeText(
                          'TODAY\nRATING',
                          provider.todaysRating == DayRating.none
                              ? 'NONE'
                              : provider.todaysRating.displayName.toUpperCase(),
                          const Color(0xFF8B7355),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Total Count Label
                const Text(
                  'TOTAL COUNT',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 20),

                // Main Counter
                Expanded(
                  child: Center(
                    child: Text(
                      '${provider.counter}',
                      style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1,
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => provider.incrementCounter(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 28,
                                    horizontal: 20,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'I have taken\na brown',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showRatingDialog,
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
                                        color: Colors.black,
                                      ),
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
      height: 90,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 4),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadgeText(String label, String value, Color color) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 4),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
