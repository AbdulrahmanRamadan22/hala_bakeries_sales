import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final InternetConnection _connection;

  ConnectivityService({InternetConnection? connection})
      : _connection = connection ?? InternetConnection();

  Stream<InternetStatus> get onStatusChange => _connection.onStatusChange;

  Future<bool> get hasInternet async => await _connection.hasInternetAccess;
}
