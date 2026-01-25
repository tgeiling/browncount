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
  int _shitStreak = 0;
  DayRating _todaysRating = DayRating.none;
  String _lastRatingDate = '';
  String _lastShitDate = '';
  bool _isInitialized = false;

  int get counter => _counter;
  int get ratingStreak => _ratingStreak;
  int get shitStreak => _shitStreak;
  DayRating get todaysRating => _todaysRating;
  String get lastRatingDate => _lastRatingDate;
  String get lastShitDate => _lastShitDate;
  bool get isInitialized => _isInitialized;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    _counter = prefs.getInt('counter') ?? 0;
    _ratingStreak = prefs.getInt('ratingStreak') ?? 0;
    _shitStreak = prefs.getInt('shitStreak') ?? 0;
    int todaysRatingValue = prefs.getInt('todaysRating') ?? -1;
    _todaysRating = dayRatingFromValue(todaysRatingValue);
    _lastRatingDate = prefs.getString('lastRatingDate') ?? '';
    _lastShitDate = prefs.getString('lastShitDate') ?? '';
    _isInitialized = true;

    notifyListeners();

    bool ratingStreakLost = false;
    bool shitStreakLost = false;

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

    // Check if shit streak is lost
    if (_lastShitDate.isNotEmpty && _lastShitDate != todayString) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayString =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (_lastShitDate != yesterdayString) {
        shitStreakLost = true;
        _shitStreak = 0;
        await prefs.setInt('shitStreak', 0);
      }
    }

    if (ratingStreakLost || shitStreakLost) {
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', _counter);
    await prefs.setInt('ratingStreak', _ratingStreak);
    await prefs.setInt('shitStreak', _shitStreak);
    await prefs.setInt('todaysRating', _todaysRating.value);
    await prefs.setString('lastRatingDate', _lastRatingDate);
    await prefs.setString('lastShitDate', _lastShitDate);
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

    // Check if shit streak should be broken
    if (_lastShitDate.isNotEmpty && _lastShitDate != todayString) {
      if (_lastShitDate != yesterdayString) {
        _shitStreak = 0;
        await prefs.setInt('shitStreak', 0);
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

    // Increment shit streak only once per day
    if (_lastShitDate != todayString) {
      _shitStreak++;
      _lastShitDate = todayString;
    }

    // Save day data with timestamp
    await _saveDayData(todayString, hasShit: true, shitTime: timestamp);
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
    bool? hasShit,
    int? rating,
    String? shitTime,
    String? ratingTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_$dateString';

    // Load existing data
    String? existingData = prefs.getString(key);
    bool currentHasShit = false;
    int currentRating = -1;
    String currentShitTime = '';
    String currentRatingTime = '';

    if (existingData != null) {
      final parts = existingData.split('|');
      if (parts.length >= 2) {
        currentHasShit = parts[0] == '1';
        currentRating = int.tryParse(parts[1]) ?? -1;
      }
      if (parts.length >= 4) {
        currentShitTime = parts[2];
        currentRatingTime = parts[3];
      }
    }

    // Update with new data
    if (hasShit != null) currentHasShit = hasShit;
    if (rating != null) currentRating = rating;
    if (shitTime != null) currentShitTime = shitTime;
    if (ratingTime != null) currentRatingTime = ratingTime;

    // Save combined data: hasShit|rating|shitTime|ratingTime
    final dataString =
        '${currentHasShit ? '1' : '0'}|$currentRating|$currentShitTime|$currentRatingTime';
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
      'hasShit': parts[0] == '1',
      'rating': int.tryParse(parts[1]) ?? -1,
      'shitTime': parts.length > 2 ? parts[2] : '',
      'ratingTime': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> updateDayData(
    String dateString,
    bool hasShit,
    int rating,
  ) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    await _saveDayData(dateString, hasShit: hasShit, rating: rating);

    // Recalculate streaks
    await _recalculateShitStreak();
    await _recalculateRatingStreak();

    // Update counter by counting all shits
    final prefs = await SharedPreferences.getInstance();
    int totalShits = 0;
    for (String key in prefs.getKeys()) {
      if (key.startsWith('day_')) {
        final dayData = prefs.getString(key);
        if (dayData != null) {
          final parts = dayData.split('|');
          if (parts[0] == '1') totalShits++;
        }
      }
    }
    _counter = totalShits;

    // Update today's rating if editing today
    if (dateString == todayString) {
      _todaysRating = dayRatingFromValue(rating);
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> _recalculateShitStreak() async {
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
        if (parts[0] == '1') {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    _shitStreak = streak;
    final todayString = '${today.year}-${today.month}-${today.day}';
    if (streak > 0) {
      _lastShitDate = todayString;
    } else {
      _lastShitDate = '';
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
    bool shitLost = false;

    if (_lastRatingDate.isNotEmpty &&
        _lastRatingDate != todayString &&
        _lastRatingDate != yesterdayString) {
      ratingLost = true;
    }

    if (_lastShitDate.isNotEmpty &&
        _lastShitDate != todayString &&
        _lastShitDate != yesterdayString) {
      shitLost = true;
    }

    return {
      'ratingLost': ratingLost,
      'shitLost': shitLost,
      'hasLost': ratingLost || shitLost,
    };
  }
}
