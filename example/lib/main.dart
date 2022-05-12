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
  final AutoReconnectWebSocket socket = AutoReconnectWebSocket(url: 'wss://demo.piesocket.com/v3/channel_1?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self', onClose: () async {
    await Future.delayed(Duration(seconds: 5));
    return true;
  }, onConnectError: (e) async {
    await Future.delayed(Duration(seconds: 5));
    return true;
  });

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    socket.connect();
    socket.stream.listen((event) {
      print("MESSAGE: $event");
    });
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      socket.addListener(() {
        setState(() {
        });
      });
    });
  }

  void _incrementCounter() {
    socket.sink?.add('test $_counter');
    setState(() {
      _counter++;
    });
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
              'Connection State: ${socket.value}',
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
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
