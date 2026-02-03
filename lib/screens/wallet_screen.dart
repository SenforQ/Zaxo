import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../constants/app_ui.dart';
import '../services/coin_service.dart';
import '../widgets/gradient_bubbles_background.dart';

class CoinProduct {
  final String productId;
  final int coins;
  final double price;
  final String priceText;

  const CoinProduct({
    required this.productId,
    required this.coins,
    required this.price,
    required this.priceText,
  });
}

const List<CoinProduct> kCoinProducts = [
  CoinProduct(productId: 'Snugg', coins: 32, price: 0.99, priceText: '\$0.99'),
  CoinProduct(productId: 'Snugg1', coins: 60, price: 1.99, priceText: '\$1.99'),
  CoinProduct(productId: 'Snugg2', coins: 96, price: 2.99, priceText: '\$2.99'),
  CoinProduct(productId: 'Snugg4', coins: 155, price: 4.99, priceText: '\$4.99'),
  CoinProduct(productId: 'Snugg5', coins: 189, price: 5.99, priceText: '\$5.99'),
  CoinProduct(productId: 'Snugg9', coins: 359, price: 9.99, priceText: '\$9.99'),
  CoinProduct(productId: 'Snugg19', coins: 729, price: 19.99, priceText: '\$19.99'),
  CoinProduct(productId: 'Snugg49', coins: 1869, price: 49.99, priceText: '\$49.99'),
  CoinProduct(productId: 'Snugg99', coins: 3799, price: 99.99, priceText: '\$99.99'),
];

const Color _themeColor = Color(0xFF260FA9);

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, Timer> _timeoutTimers = {};
  final NumberFormat _coinsFormat = NumberFormat.decimalPattern();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails> _products = {};

  int _currentCoins = 0;
  int _selectedIndex = 0;
  bool _isPurchasing = false;
  bool _isAvailable = false;
  int _retryCount = 0;

  static const int _maxRetries = 3;
  static const int _timeoutDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    _initializeUserAndLoadCoins();
    _checkConnectivityAndInit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    super.dispose();
  }

  Future<void> _initializeUserAndLoadCoins() async {
    await CoinService.initializeNewUser();
    await _loadCoins();
  }

  Future<void> _loadCoins() async {
    final coins = await CoinService.getCurrentCoins();
    if (!mounted) return;
    setState(() {
      _currentCoins = coins;
    });
  }

  Future<void> _checkConnectivityAndInit() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasConnection = results.isNotEmpty &&
          !(results.length == 1 && results.contains(ConnectivityResult.none));
      if (!hasConnection) {
        _showToast('No internet connection. Please check your network.');
        return;
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
    await _initIAP();
  }

  Future<void> _initIAP() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
      });
      if (!available) {
        _showToast('In-App Purchase not available.');
        return;
      }

      final ids = kCoinProducts.map((e) => e.productId).toSet();
      final response = await _inAppPurchase.queryProductDetails(ids);

      if (response.error != null) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          await _initIAP();
          return;
        }
        _showToast('Failed to load products: ${response.error!.message}');
      }

      setState(() {
        _products = {for (final p in response.productDetails) p.id: p};
      });

      _subscription ??= _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) => _showToast('Purchase error: $error'),
        onDone: () => _subscription?.cancel(),
      );
    } catch (e) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        await _initIAP();
      } else {
        _showToast('Failed to initialize in-app purchases.');
      }
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _inAppPurchase.completePurchase(purchase);
          final product = kCoinProducts.firstWhere(
            (p) => p.productId == purchase.productID,
            orElse: () => const CoinProduct(
                productId: '', coins: 0, price: 0, priceText: ''),
          );
          if (product.coins > 0) {
            final success = await CoinService.addCoins(product.coins);
            if (success) {
              await _loadCoins();
              _showToast('Successfully purchased ${product.coins} coins!');
            } else {
              _showToast('Failed to add coins. Please contact support.');
            }
          }
          break;
        case PurchaseStatus.error:
          _showToast('Purchase failed: ${purchase.error?.message ?? ''}');
          break;
        case PurchaseStatus.canceled:
          _showToast('Purchase canceled.');
          break;
        default:
          break;
      }
    }
    _clearPurchaseState();
  }

  void _clearPurchaseState() {
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
    });
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
  }

  Future<void> _handleConfirmPurchase() async {
    if (!_isAvailable) {
      _showToast('Store is not available.');
      return;
    }
    final selectedProduct = kCoinProducts[_selectedIndex];
    setState(() {
      _isPurchasing = true;
    });

    _timeoutTimers['purchase'] = Timer(
      const Duration(seconds: _timeoutDurationSeconds),
      _handlePurchaseTimeout,
    );

    try {
      ProductDetails? productDetails = _products[selectedProduct.productId];
      productDetails ??= _products.isNotEmpty ? _products.values.first : null;
      if (productDetails == null) {
        throw Exception('No products available for purchase.');
      }
      final param = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyConsumable(purchaseParam: param);
    } catch (e) {
      _timeoutTimers['purchase']?.cancel();
      _timeoutTimers.remove('purchase');
      _showToast('Purchase failed: $e');
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  void _handlePurchaseTimeout() {
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
    });
    _timeoutTimers['purchase']?.cancel();
    _timeoutTimers.remove('purchase');
    _showToast('Payment timeout. Please try again.');
  }

  void _showToast(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _showCoinInfoDialog,
              icon: Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                    .copyWith(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _coinsFormat.format(_currentCoins),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: kCoinProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isPurchasing)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final product = kCoinProducts[index];
    final isSelected = _selectedIndex == index;
    final priceLabel = _getPriceLabel(product);

    return GestureDetector(
      onTap: _isPurchasing
          ? null
          : () {
              HapticFeedback.lightImpact();
              _onProductSelected(index);
            },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? _themeColor.withOpacity(0.9)
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/applogo.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${product.coins} Coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : _themeColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Text(
                priceLabel,
                style: TextStyle(
                  color: isSelected ? _themeColor : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceLabel(CoinProduct product) {
    final productDetails = _products[product.productId];
    if (productDetails != null && productDetails.price.isNotEmpty) {
      final rawPrice = productDetails.rawPrice;
      final numericPrice = rawPrice is num
          ? rawPrice
          : num.tryParse(rawPrice.toString()) ?? 0;
      return '\$${numericPrice.toStringAsFixed(2)}';
    }
    return product.priceText;
  }

  void _onProductSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final product = kCoinProducts[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/applogo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Purchase',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Purchase ${product.coins} coins for ${_getPriceLabel(product)}?',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleConfirmPurchase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Purchase',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCoinInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/applogo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Coin Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _CoinRule(
              number: '1',
              text: 'Using AI music generation costs coins per use.',
            ),
            SizedBox(height: 16),
            _CoinRule(
              number: '2',
              text: 'Using AI image creation costs coins per use.',
            ),
            SizedBox(height: 16),
            _CoinRule(
              number: '3',
              text: 'Coins are obtained via in-app purchases.',
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinRule extends StatelessWidget {
  const _CoinRule({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _themeColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
