import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  Currency? _fromCurrency;
  Currency? _toCurrency;
  double _result = 0;
  final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'ru_RU');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().loadCurrencies();
    });
  }

  void _performConversion() {
    final provider = context.read<CurrencyProvider>();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    
    if (amount != null && _fromCurrency != null && _toCurrency != null) {
      setState(() {
        _result = provider.convertCurrency(amount, _fromCurrency!, _toCurrency!);
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _performConversion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют ЦБ РФ'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<CurrencyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCurrencies(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.currencies.isEmpty) {
            return const Center(child: Text('Нет данных о валютах'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Сумма',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          onChanged: (_) => _performConversion(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Currency>(
                                decoration: InputDecoration(
                                  labelText: 'Из',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                value: _fromCurrency,
                                items: provider.currencies
                                    .map((currency) => DropdownMenuItem(
                                          value: currency,
                                          child: Text(
                                              '${currency.charCode} - ${currency.name}'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _fromCurrency = value);
                                  _performConversion();
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton(
                                icon: const Icon(Icons.swap_horiz),
                                onPressed: _swapCurrencies,
                                color: Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<Currency>(
                                decoration: InputDecoration(
                                  labelText: 'В',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                value: _toCurrency,
                                items: provider.currencies
                                    .map((currency) => DropdownMenuItem(
                                          value: currency,
                                          child: Text(
                                              '${currency.charCode} - ${currency.name}'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _toCurrency = value);
                                  _performConversion();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_fromCurrency != null && _toCurrency != null)
                  Card(
                    elevation: 4,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Результат конвертации',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_numberFormat.format(double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0)} ${_fromCurrency!.charCode} =',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${_numberFormat.format(_result)} ${_toCurrency!.charCode}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Курс: 1 ${_fromCurrency!.charCode} = ${_numberFormat.format(context.read<CurrencyProvider>().convertCurrency(1, _fromCurrency!, _toCurrency!))} ${_toCurrency!.charCode}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Курсы валют ЦБ РФ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy').format(DateTime.now()),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.currencies.length,
                          itemBuilder: (context, index) {
                            final currency = provider.currencies[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  currency.charCode,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(currency.name),
                              trailing: Text(
                                '${_numberFormat.format(currency.value)} ₽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              dense: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CurrencyProvider>().loadCurrencies(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}