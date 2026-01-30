// provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DayRating { none, terrible, bad, okay, good, amazing }

DayRating dayRatingFromValue(int value) {
  switch (value) {
    case 0:
      return DayRating.terrible;
    case 1:
      return DayRating.bad;
    case 2:
      return DayRating.okay;
    case 3:
      return DayRating.good;
    case 4:
      return DayRating.amazing;
    default:
      return DayRating.none;
  }
}

extension DayRatingExtension on DayRating {
  String get displayName {
    switch (this) {
      case DayRating.none:
        return 'None';
      case DayRating.terrible:
        return 'Terrible';
      case DayRating.bad:
        return 'Bad';
      case DayRating.okay:
        return 'Okay';
      case DayRating.good:
        return 'Good';
      case DayRating.amazing:
        return 'Amazing';
    }
  }

  int get value {
    switch (this) {
      case DayRating.none:
        return -1;
      case DayRating.terrible:
        return 0;
      case DayRating.bad:
        return 1;
      case DayRating.okay:
        return 2;
      case DayRating.good:
        return 3;
      case DayRating.amazing:
        return 4;
    }
  }
}

class AppProvider extends ChangeNotifier {
  int _counter = 0;
  int _ratingStreak = 0;
  int _brownStreak = 0;
  DayRating _todaysRating = DayRating.none;
  String _lastRatingDate = '';
  String _lastBrownDate = '';
  bool _isInitialized = false;

  int get counter => _counter;
  int get ratingStreak => _ratingStreak;
  int get brownStreak => _brownStreak;
  DayRating get todaysRating => _todaysRating;
  String get lastRatingDate => _lastRatingDate;
  String get lastBrownDate => _lastBrownDate;
  bool get isInitialized => _isInitialized;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    _counter = prefs.getInt('counter') ?? 0;
    _ratingStreak = prefs.getInt('ratingStreak') ?? 0;
    _brownStreak = prefs.getInt('brownStreak') ?? 0;
    int todaysRatingValue = prefs.getInt('todaysRating') ?? -1;
    _todaysRating = dayRatingFromValue(todaysRatingValue);
    _lastRatingDate = prefs.getString('lastRatingDate') ?? '';
    _lastBrownDate = prefs.getString('lastBrownDate') ?? '';
    _isInitialized = true;

    notifyListeners();

    bool ratingStreakLost = false;
    bool brownStreakLost = false;

    // Check if rating streak is lost
    if (_lastRatingDate.isNotEmpty && _lastRatingDate != todayString) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayString =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (_lastRatingDate != yesterdayString) {
        ratingStreakLost = true;
        _ratingStreak = 0;
        await prefs.setInt('ratingStreak', 0);
      }

      // Reset today's rating for new day
      if (_lastRatingDate != todayString) {
        _todaysRating = DayRating.none;
        await prefs.setInt('todaysRating', -1);
      }
    }

    // Check if brown streak is lost
    if (_lastBrownDate.isNotEmpty && _lastBrownDate != todayString) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayString =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (_lastBrownDate != yesterdayString) {
        brownStreakLost = true;
        _brownStreak = 0;
        await prefs.setInt('brownStreak', 0);
      }
    }

    if (ratingStreakLost || brownStreakLost) {
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', _counter);
    await prefs.setInt('ratingStreak', _ratingStreak);
    await prefs.setInt('brownStreak', _brownStreak);
    await prefs.setInt('todaysRating', _todaysRating.value);
    await prefs.setString('lastRatingDate', _lastRatingDate);
    await prefs.setString('lastBrownDate', _lastBrownDate);
  }

  Future<void> _checkAndUpdateStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayString =
        '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    bool streaksChanged = false;

    // Check if rating streak should be broken
    if (_lastRatingDate.isNotEmpty && _lastRatingDate != todayString) {
      if (_lastRatingDate != yesterdayString) {
        _ratingStreak = 0;
        await prefs.setInt('ratingStreak', 0);
        streaksChanged = true;
      }

      // Reset today's rating for new day
      if (_todaysRating != DayRating.none) {
        _todaysRating = DayRating.none;
        await prefs.setInt('todaysRating', -1);
        streaksChanged = true;
      }
    }

    // Check if brown streak should be broken
    if (_lastBrownDate.isNotEmpty && _lastBrownDate != todayString) {
      if (_lastBrownDate != yesterdayString) {
        _brownStreak = 0;
        await prefs.setInt('brownStreak', 0);
        streaksChanged = true;
      }
    }

    if (streaksChanged) {
      await _saveData();
    }
  }

  Future<void> incrementCounter() async {
    // Check streaks before any action
    await _checkAndUpdateStreaks();

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final timestamp = DateTime.now().toIso8601String();

    _counter++;

    // Get current brown count for today
    final dayDetails = await getDayDetails(todayString);
    int currentBrownCount = dayDetails?['brownCount'] ?? 0;
    currentBrownCount++;

    // Increment brown streak only once per day
    if (_lastBrownDate != todayString) {
      _brownStreak++;
      _lastBrownDate = todayString;
    }

    // Save day data with brown count and timestamp
    await _saveDayData(
      todayString,
      brownCount: currentBrownCount,
      brownTime: timestamp,
    );
    await _saveData();
    notifyListeners();
  }

  Future<void> setRating(DayRating rating) async {
    // Check streaks before any action
    await _checkAndUpdateStreaks();

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final timestamp = DateTime.now().toIso8601String();

    _todaysRating = rating;

    // Increment rating streak only once per day
    if (_lastRatingDate != todayString) {
      _ratingStreak++;
      _lastRatingDate = todayString;
    }

    // Save day data with timestamp
    await _saveDayData(
      todayString,
      rating: rating.value,
      ratingTime: timestamp,
    );
    await _saveData();
    notifyListeners();
  }

  Future<void> _saveDayData(
    String dateString, {
    int? brownCount,
    int? rating,
    String? brownTime,
    String? ratingTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_$dateString';

    // Load existing data
    String? existingData = prefs.getString(key);
    int currentBrownCount = 0;
    int currentRating = -1;
    String currentBrownTime = '';
    String currentRatingTime = '';

    if (existingData != null) {
      final parts = existingData.split('|');
      if (parts.length >= 2) {
        currentBrownCount = int.tryParse(parts[0]) ?? 0;
        currentRating = int.tryParse(parts[1]) ?? -1;
      }
      if (parts.length >= 4) {
        currentBrownTime = parts[2];
        currentRatingTime = parts[3];
      }
    }

    // Update with new data
    if (brownCount != null) currentBrownCount = brownCount;
    if (rating != null) currentRating = rating;
    if (brownTime != null) currentBrownTime = brownTime;
    if (ratingTime != null) currentRatingTime = ratingTime;

    // Save combined data: brownCount|rating|brownTime|ratingTime
    final dataString =
        '$currentBrownCount|$currentRating|$currentBrownTime|$currentRatingTime';
    await prefs.setString(key, dataString);
  }

  Future<Map<String, dynamic>?> getDayDetails(String dateString) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_$dateString';
    final data = prefs.getString(key);

    if (data == null) return null;

    final parts = data.split('|');
    if (parts.length < 2) return null;

    return {
      'brownCount': int.tryParse(parts[0]) ?? 0,
      'rating': int.tryParse(parts[1]) ?? -1,
      'brownTime': parts.length > 2 ? parts[2] : '',
      'ratingTime': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> updateDayData(
    String dateString,
    int brownCount,
    int rating,
  ) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    await _saveDayData(dateString, brownCount: brownCount, rating: rating);

    // Recalculate streaks
    await _recalculateBrownStreak();
    await _recalculateRatingStreak();

    // Update counter by counting all browns
    final prefs = await SharedPreferences.getInstance();
    int totalBrowns = 0;
    for (String key in prefs.getKeys()) {
      if (key.startsWith('day_')) {
        final dayData = prefs.getString(key);
        if (dayData != null) {
          final parts = dayData.split('|');
          int count = int.tryParse(parts[0]) ?? 0;
          totalBrowns += count;
        }
      }
    }
    _counter = totalBrowns;

    // Update today's rating if editing today
    if (dateString == todayString) {
      _todaysRating = dayRatingFromValue(rating);
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> _recalculateBrownStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateString =
          '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      final dayData = prefs.getString('day_$dateString');

      if (dayData != null) {
        final parts = dayData.split('|');
        int brownCount = int.tryParse(parts[0]) ?? 0;
        if (brownCount > 0) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    _brownStreak = streak;
    final todayString = '${today.year}-${today.month}-${today.day}';
    if (streak > 0) {
      _lastBrownDate = todayString;
    } else {
      _lastBrownDate = '';
    }
  }

  Future<void> _recalculateRatingStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateString =
          '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      final dayData = prefs.getString('day_$dateString');

      if (dayData != null) {
        final parts = dayData.split('|');
        if (parts.length > 1 && parts[1] != '-1') {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    _ratingStreak = streak;
    final todayString = '${today.year}-${today.month}-${today.day}';
    if (streak > 0) {
      _lastRatingDate = todayString;
    } else {
      _lastRatingDate = '';
    }
  }

  Map<String, dynamic> getStreakLostInfo() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayString =
        '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    bool ratingLost = false;
    bool brownLost = false;

    if (_lastRatingDate.isNotEmpty &&
        _lastRatingDate != todayString &&
        _lastRatingDate != yesterdayString) {
      ratingLost = true;
    }

    if (_lastBrownDate.isNotEmpty &&
        _lastBrownDate != todayString &&
        _lastBrownDate != yesterdayString) {
      brownLost = true;
    }

    return {
      'ratingLost': ratingLost,
      'brownLost': brownLost,
      'hasLost': ratingLost || brownLost,
    };
  }
}
