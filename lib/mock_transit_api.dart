class MockTransitAPI {
  static final List<Map<String, String>> registeredDrivers = [
    {
      'name': 'Juan Pérez',
      'plateNumber': 'ABC123',
      'phone': '1234567890',
    },
    {
      'name': 'Jose Hernandez',
      'plateNumber': 'ABC321',
      'phone': '1234567890',
    },
    {
      'name': 'Sergio Meneses',
      'plateNumber': 'LMTUWU',
      'phone': '1234567890',
    },
  ];

  static bool verifyDriverData(String name, String plateNumber, String phone) {
    return registeredDrivers.any((driver) =>
        driver['name'] == name &&
        driver['plateNumber'] == plateNumber &&
        driver['phone'] == phone);
  }
}
