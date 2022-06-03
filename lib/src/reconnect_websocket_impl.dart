import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

class AutoReconnectWebSocket {

  AutoReconnectWebSocket({required this.url, required this.onClosed,});

  /// current WebSocket channel
  IOWebSocketChannel? _wsChannel;
  final String url;
  /// Forward message from channel -> stream
  StreamSubscription? _subscription;
  /// Data stream
  final StreamController _innerStream = StreamController.broadcast();
  /// Sink for sending messages.
  StreamSink? get sink => _wsChannel?.sink;
  /// Stream for receiving messages. Do not use it for sending messages.
  Stream get stream => _innerStream.stream;
  /// Callback when socket is closed
  final Future<bool> Function(dynamic error)? onClosed;
  bool _released = false;
  ConnectionState _state = ConnectionState.disconnected;
  ConnectionState get state => _state;

  final List<void Function(ConnectionState)> _stateChangeListeners = [];
  List<void Function(ConnectionState)> get stateChangeListeners => _stateChangeListeners;

  void _setState(ConnectionState value) {
    if (_state == value) return;
    _state = value;
    for (var callback in _stateChangeListeners) {
      callback(_state);
    }
  }

  Future<bool> _connectInternal() async {
    assert(_wsChannel == null && _subscription == null && url.isNotEmpty);
    try {
      _setState(ConnectionState.connecting);
      final ws = await WebSocket.connect(url);
      _log('Connected to WebSocket: $url');
      _wsChannel = IOWebSocketChannel(ws);
      _subscription = _wsChannel!.stream.listen(
            (dynamic message) {
          _innerStream.add(message);
        },
        onDone: () async {
          _log('WebSocket closed');
          _setState(ConnectionState.disconnected);
          if (onClosed != null) {
            final _reconnect = await onClosed!.call(_wsChannel?.closeReason);
            if (_reconnect) {
              _log("WebSocket reconnecting...");
              reconnect();
            }
          }
        },
        onError: (error) {
          _log('WebSocket error $error');
        },
      );
      _setState(ConnectionState.connected);
      return true;
    } catch (e) {
      _log('Error creating WebSocket: $e');
      _setState(ConnectionState.disconnected);
      if (onClosed != null) {
        final _reconnect = await onClosed!.call(e);
        if (_reconnect) {
          _log("WebSocket reconnecting...");
          final ret = await reconnect();
          return ret;
        }
      }
    }
    return false;
  }

  void _releaseConnection() {
    _subscription?.cancel();
    _subscription = null;
    _wsChannel?.innerWebSocket?.close();
    _wsChannel = null;
  }

  Future connect() async {
    return reconnect();
  }

  Future<bool> reconnect() async {
    if (_released) {
      throw Exception("AutoReconnectWebSocket was used after being disposed.");
    }
    _releaseConnection();
    return _connectInternal();
  }

  void dispose() {
    if (!_released) {
      _stateChangeListeners.clear();
      _releaseConnection();
      _innerStream.close();
      _released = true;
    }
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
}

void _log(String msg) {
  log(msg);
}