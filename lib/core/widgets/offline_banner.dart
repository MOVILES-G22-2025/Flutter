// lib/core/widgets/offline_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';

class OfflineBanner extends StatefulWidget {
  /// Stream que emite `true` cuando hay conexión, `false` cuando NO.
  final Stream<bool> connectivityStream;

  const OfflineBanner({Key? key, required this.connectivityStream})
      : super(key: key);

  @override
  _OfflineBannerState createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  int _status = 0; // 0=none, 1=offline, 2=back online
  late StreamSubscription<bool> _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.connectivityStream.listen((online) {
      if (!online && _status != 1) {
        setState(() => _status = 1);
      } else if (online && _status == 1) {
        setState(() => _status = 2);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _status = 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 0) return const SizedBox.shrink();

    final isOffline = _status == 1;
    final bgColor = isOffline
        ? Colors.redAccent.withOpacity(0.9)
        : Colors.green.withOpacity(0.9);
    final icon = isOffline ? Icons.cloud_off : Icons.cloud_queue;

    // Obtener alto de status bar para no sobreponer dos SafeAreas
    final top = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () {
        if (isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please connect to internet to have all functions',
                textAlign: TextAlign.center,
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.only(top: top + 4, bottom: 4),
        color: bgColor,
        child: Center(
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
