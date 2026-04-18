import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:prusa_monitor/services/printer_service.dart';

@GenerateMocks([http.Client, WebSocketChannel, PrinterService])
void main() {}
