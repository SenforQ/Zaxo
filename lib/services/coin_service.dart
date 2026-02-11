import 'prefs_service.dart';

class CoinService {
  CoinService._();

  static final CoinService _instance = CoinService._();
  static CoinService get instance => _instance;

  static const int initialCoins = 20;

  static Future<void> initializeNewUser() async {
    final coins = await PrefsService.shared.getUserCoins();
    if (coins == 0) {
      await PrefsService.shared.setUserCoins(initialCoins);
    }
  }

  static Future<int> getCurrentCoins() async {
    return await PrefsService.shared.getUserCoins();
  }

  static Future<bool> addCoins(int amount) async {
    if (amount <= 0) return false;
    final current = await PrefsService.shared.getUserCoins();
    await PrefsService.shared.setUserCoins(current + amount);
    return true;
  }

  static Future<bool> deductCoins(int amount) async {
    if (amount <= 0) return false;
    return await PrefsService.shared.deductCoins(amount);
  }
}
