import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
// import 'package:http/http.dart' as http; // Закомментировано, пока не используется в этом файле

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Исправлено super.key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VLESS VPN Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VlessClientScreen(),
    );
  }
}

class VlessClientScreen extends StatefulWidget {
  const VlessClientScreen({super.key}); // Исправлено super.key

  @override
  State<VlessClientScreen> createState() => _VlessClientScreenState();
}

  String _serverDelay = "N/A";

  final String _defaultVlessLink = "vless://dd7ebe71-95bc-46fd-94ee-ed57b904ef7f@103.56.84.9:443?type=tcp&security=reality&pbk=SuaSfc9lxuMKnm7ku4ksgLK72Tl9Ge4bs2a7dmD7Tzo&fp=chrome&sni=www.microsoft.com&sid=22c544ee&spx=%2F#Yar3";

class _VlessClientScreenState extends State<VlessClientScreen> {
  late final FlutterV2ray flutterV2ray;
  String _connectionStatus = "Disconnected";
  V2RayURL? _parsedConfig;
  String _currentRemark = "Default Server";

  @override
  void initState() {
    super.initState();
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        setState(() {
          _connectionStatus = status.toString();
        });
        print("V2Ray Status: $status");
      },
    );
    _initializeAndParseDefault();
  }

  Future<void> _initializeAndParseDefault() async {
    await flutterV2ray.initializeV2Ray();
    await _parseLink(_defaultVlessLink);
  }

  Future<void> _parseLink(String link) async {
    try {
      _parsedConfig = FlutterV2ray.parseFromURL(link);
      setState(() {
        _currentRemark = _parsedConfig?.remark ?? "Unknown Server";
      });
      _showSnackBar("Link parsed successfully!");
      print("Remark: ${_parsedConfig?.remark}");
    } catch (e) {
      _showSnackBar("Error parsing link: $e", isError: true);
      print("Parsing error: $e");
    }
  }

  Future<void> _connectV2Ray() async {
    if (_parsedConfig == null) {
      _showSnackBar("No server configured. Please parse a link first.", isError: true);
      return;
    }

    if (await flutterV2ray.requestPermission()) {
      flutterV2ray.startV2Ray(
        remark: _parsedConfig!.remark,
        config: _parsedConfig!.getFullConfiguration(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );
    } else {
      _showSnackBar("VPN permission not granted.", isError: true);
    }
  }

  Future<void> _disconnectV2Ray() async {
    await flutterV2ray.stopV2Ray();
    _showSnackBar("Disconnected.");
  }

  Future<void> _getDelay() async {
    if (_parsedConfig == null) {
      _showSnackBar("No server configured. Cannot get delay.", isError: true);
      return;
    }
    setState(() => _serverDelay = "Measuring...");
    try {
      final delay = await flutterV2ray.getServerDelay(config: _parsedConfig!.getFullConfiguration());
      setState(() {
        _serverDelay = "$delay ms";
      });
      _showSnackBar("Server Delay: $_serverDelay");
    } catch (e) {
      setState(() => _serverDelay = "Error");
      _showSnackBar("Failed to get delay: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Phantom',
            style: TextStyle(color: Color.fromARGB(255, 65, 65, 65)),),
        backgroundColor: Colors.black87,
      ),
      body: 
      Stack(
        children: <Widget>[

          Image.asset(
          'assets/images/background3.gif', // Укажите правильный путь к вашему файлу
          height: MediaQuery.of(context).size.height, // Высота на весь экран
          width: MediaQuery.of(context).size.width,   // Ширина на весь экран
          fit: BoxFit.cover, // Растягиваем GIF, чтобы он заполнил экран без искажений
        ),
      
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Current Server:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentRemark,
                          style: const TextStyle(fontSize: 22, color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text("Status: $_connectionStatus", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Delay: $_serverDelay", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _connectV2Ray,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text("Connect"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _disconnectV2Ray,
                  icon: const Icon(Icons.cancel),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.redAccent, // ИСПРАВЛЕНО ЗДЕСЬ
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _getDelay,
                  icon: const Icon(Icons.speed),
                  label: const Text("Measure Delay"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                // В будущем здесь будет кнопка для открытия списка серверов
                // ElevatedButton(
                //   onPressed: () {
                //     // TODO: Открыть экран выбора серверов
                //   },
                //   child: Text("Select Server"),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}