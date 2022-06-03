import 'package:flutter/material.dart';
import 'package:auto_reconnect_websocket/src/reconnect_websocket_impl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  dynamic? lastMessage;
  final AutoReconnectWebSocket socket = AutoReconnectWebSocket(
      url:
          'wss://demo.piesocket.com/v3/channel_1?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self',
      onClosed: (e) async {
        await Future.delayed(const Duration(seconds: 5));
        return true;
      });

  @override
  void initState() {
    super.initState();
    socket.connect();
    socket.stream.listen((msg) {
      print("MESSAGE: $msg");
      setState(() {
        lastMessage = msg;
      });
    });
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      socket.stateChangeListeners.add((state) {
        setState(() {});
      });
    });
  }

  void _incrementCounter() {
    _counter++;
    socket.sink?.add('test $_counter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Connection State: ${socket.state}',
            ),
            Text(
              'LastMessage: $lastMessage',
            ),
            const Text(
              'Test Url: https://www.piesocket.com/websocket-tester',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
