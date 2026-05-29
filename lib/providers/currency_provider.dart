import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../services/api_service.dart';

class CurrencyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Currency> _currencies = [];
  bool _isLoading = false;
  String? _error;

  List<Currency> get currencies => _currencies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrencies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currencies = await _apiService.fetchCurrencies();
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  double convertCurrency(double amount, Currency from, Currency to) {
    if (from.charCode == to.charCode) return amount;
    
    double amountInRubles = from.charCode == 'RUB' 
        ? amount 
        : amount * from.ratePerUnit;
    
    return to.charCode == 'RUB' 
        ? amountInRubles 
        : amountInRubles / to.ratePerUnit;
  }
}