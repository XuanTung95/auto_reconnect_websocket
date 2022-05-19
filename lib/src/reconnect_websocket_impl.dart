import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

class AutoReconnectWebSocket extends ValueNotifier<ConnectionState> {
  /// current WebSocket channel
  IOWebSocketChannel? _wsChannel;
  final String url;
  /// Forward message from channel -> stream
  StreamSubscription? _subscription;
  /// Data stream
  final StreamController _innerStream = StreamController();
  /// Sink to send message
  StreamSink? get sink => _wsChannel?.sink;
  /// Stream to receive message
  Stream get stream => _innerStream.stream;
  /// Handle when socket is closed
  final Future<bool> Function() onClose;
  /// Handle when cannot create a connection
  final Future<bool> Function(dynamic error) onConnectError;
  bool _released = false;

  AutoReconnectWebSocket({required this.url, required this.onClose, required this.onConnectError})
      : super(ConnectionState.disconnected);

  Future<bool> _connectInternal() async {
    assert(_wsChannel == null && _subscription == null && url.isNotEmpty);
    try {
      value = ConnectionState.connecting;
      final ws = await WebSocket.connect(url);
      _log('Connected to WebSocket: $url');
      _wsChannel = IOWebSocketChannel(ws);
      _subscription = _wsChannel!.stream.listen(
            (dynamic message) {
          // forward message to out stream
          _log('ws data: $message');
          _innerStream.add(message);
        },
        onDone: () async {
          _log('ws closed');
          value = ConnectionState.disconnected;
          final _reconnect = await onClose();
          if (_reconnect) {
            _log("Reconnecting...");
            reconnect();
          }
        },
        onError: (error) {
          _log('ws error $error');
        },
      );
      value = ConnectionState.connected;
      return true;
    } catch (e) {
      _log('Create new WebSocket connection error: $e');
      value = ConnectionState.disconnected;
      // handle init WebSocket error
      final _reconnect = await onConnectError(e);
      if (_reconnect) {
        _log("Reconnecting...");
        final ret = await reconnect();
        return ret;
      }
    }
    return false;
  }

  void _releaseConnection() {
    // cancel subscription
    _subscription?.cancel();
    _subscription = null;
    _wsChannel?.innerWebSocket?.close();
    _wsChannel = null;
  }

  Future connect() async {
    return reconnect();
  }

  Future<bool> reconnect() async {
    _releaseConnection();
    return _connectInternal();
  }

  @override
  void dispose() {
    super.dispose();
    _releaseConnection();
    _innerStream.close();
    _released = true;
  }
}

enum ConnectionState {
  connected,
  connecting,
  disconnected,
}


void _log(String msg) {
  print(msg);
}