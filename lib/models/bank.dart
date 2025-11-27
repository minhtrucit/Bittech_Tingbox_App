class Bank {
  final int id;
  final String name;
  final String code;
  final String shortName;
  final String logo;
  final int transferSupported;

  Bank({
    required this.id,
    required this.name,
    required this.code,
    required this.shortName,
    required this.logo,
    required this.transferSupported,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      shortName: json['shortName'],
      logo: json['logo'],
      transferSupported: json['transferSupported'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'shortName': shortName,
      'logo': logo,
      'transferSupported': transferSupported,
    };
  }

  static String getTransferSupportedName(int value) {
    switch (value) {
      case 1:
        return 'Có';
      case 0:
        return 'Không';
      default:
        return 'Không xác định';
    }
  }

  static List<Bank> getTransferSupportedBanks(List<Bank> banks) {
    return banks.where((bank) => bank.transferSupported == 1).toList();
  }
}
