class Currency {
  final String id;
  final String numCode;
  final String charCode;
  final int nominal;
  final String name;
  final double value;

  Currency({
    required this.id,
    required this.numCode,
    required this.charCode,
    required this.nominal,
    required this.name,
    required this.value,
  });

  factory Currency.fromXml(Map<String, String> data) {
    return Currency(
      id: data['ID'] ?? '',
      numCode: data['NumCode'] ?? '',
      charCode: data['CharCode'] ?? '',
      nominal: int.tryParse(data['Nominal'] ?? '1') ?? 1,
      name: data['Name'] ?? '',
      value: double.tryParse(data['Value']?.replaceAll(',', '.') ?? '0') ?? 0,
    );
  }

  double get ratePerUnit => value / nominal;
}