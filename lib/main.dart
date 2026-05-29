import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:enough_convert/enough_convert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвертер валют',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CurrencyConverter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  Map<String, double> _rates = {};
  Map<String, String> _names = {};
  bool _isLoading = true;
  String? _error;
  
  String _from = 'RUB';
  String _to = 'USD';
  final _amountController = TextEditingController();
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.cbr.ru/scripts/XML_daily.asp'),
      );

      if (response.statusCode == 200) {
        final windows1251 = Windows1251Codec();
        final decodedBody = windows1251.decode(response.bodyBytes);
        
        final document = XmlDocument.parse(decodedBody);
        final valutes = document.findAllElements('Valute');
        
        _rates = {'RUB': 1.0};
        _names = {'RUB': 'Российский рубль'};
        
        for (var valute in valutes) {
          final charCode = valute.findElements('CharCode').first.innerText;
          final name = valute.findElements('Name').first.innerText;
          final value = double.parse(
            valute.findElements('Value').first.innerText.replaceAll(',', '.')
          );
          final nominal = int.parse(
            valute.findElements('Nominal').first.innerText
          );
          
          _rates[charCode] = value / nominal;
          _names[charCode] = name;
        }
        
        setState(() => _isLoading = false);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculate() {
    final text = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(text);
    
    if (amount != null && _rates.containsKey(_from) && _rates.containsKey(_to)) {
      setState(() {
        final rubles = _from == 'RUB' ? amount : amount * _rates[_from]!;
        _result = _to == 'RUB' ? rubles : rubles / _rates[_to]!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Конвертер валют',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка курсов...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Поле ввода
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                          decoration: InputDecoration(
                            labelText: 'Сумма',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.money),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          onChanged: (_) => _calculate(),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        // Выбор валют - в колонку на маленьких экранах
                        isSmallScreen
                            ? Column(
                                children: [
                                  _buildCurrencyDropdown(
                                    value: _from,
                                    label: 'Из какой валюты',
                                    onChanged: (val) {
                                      setState(() => _from = val!);
                                      _calculate();
                                    },
                                  ),
                                  SizedBox(height: 8),
                                  Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.swap_vert, color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          final temp = _from;
                                          _from = _to;
                                          _to = temp;
                                        });
                                        _calculate();
                                      },
                                    ),
                                  ),
                                  _buildCurrencyDropdown(
                                    value: _to,
                                    label: 'В какую валюту',
                                    onChanged: (val) {
                                      setState(() => _to = val!);
                                      _calculate();
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildCurrencyDropdown(
                                      value: _from,
                                      label: 'Из',
                                      onChanged: (val) {
                                        setState(() => _from = val!);
                                        _calculate();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: IconButton(
                                      icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          final temp = _from;
                                          _from = _to;
                                          _to = temp;
                                        });
                                        _calculate();
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCurrencyDropdown(
                                      value: _to,
                                      label: 'В',
                                      onChanged: (val) {
                                        setState(() => _to = val!);
                                        _calculate();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Результат
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_amountController.text.isEmpty ? "0" : _amountController.text} $_from =',
                                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_result.toStringAsFixed(2)} $_to',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        
                        // Заголовок списка
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Курсы валют:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _loadData,
                              icon: Icon(Icons.refresh, size: isSmallScreen ? 16 : 18),
                              label: Text('Обновить'),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Список валют
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rates.length,
                          itemBuilder: (context, index) {
                            final code = _rates.keys.elementAt(index);
                            final rate = _rates[code]!;
                            final name = _names[code]!;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: isSmallScreen ? 16 : 20,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    code,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                ),
                                trailing: Text(
                                  code == 'RUB' 
                                      ? '1.00 ₽' 
                                      : '${rate.toStringAsFixed(4)} ₽',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 13 : 16,
                                  ),
                                ),
                                dense: isSmallScreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      items: _rates.keys.map((code) {
        return DropdownMenuItem(
          value: code,
          child: Text(
            '$code - ${_names[code]}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}