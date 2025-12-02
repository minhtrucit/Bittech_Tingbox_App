class MockBluetoothDevice {
  final String name;
  final String address;
  bool isConnected;

  MockBluetoothDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address, 'isConnected': isConnected};
  }

  factory MockBluetoothDevice.fromJson(Map<String, dynamic> json) {
    return MockBluetoothDevice(
      name: json['name'] as String,
      address: json['address'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
