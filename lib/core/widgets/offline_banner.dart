// lib/core/widgets/offline_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';

// Widget that shows a banner when the device is offline
class OfflineBanner extends StatefulWidget {
  /// Stream that emits `true` when online, `false` when offline
  final Stream<bool> connectivityStream;

  const OfflineBanner({Key? key, required this.connectivityStream})
      : super(key: key);

  @override
  _OfflineBannerState createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  // Status: 0=none, 1=offline, 2=back online
  int _status = 0;
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
        ? Colors.redAccent.withOpacity(0.95)
        : Colors.green.withOpacity(0.95);
    final icon = isOffline ? Icons.cloud_off : Icons.cloud_queue;

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
      child: Container(
        width: double.infinity,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
