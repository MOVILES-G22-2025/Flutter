import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/core/services/connectivity_service.dart';
import 'package:senemarket/core/widgets/offline_banner.dart';

class AppWrapper extends StatelessWidget {
  final Widget child;

  const AppWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectivityService = context.read<ConnectivityService>();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return StreamBuilder<bool>(
      stream: connectivityService.isOnline$,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        return Column(
          children: [
            if (!isOnline)
              Padding(
                padding: EdgeInsets.only(top: statusBarHeight),
                child: OfflineBanner(
                  connectivityStream: connectivityService.isOnline$,
                ),
              ),
            Expanded(
              child: child,
            ),
          ],
        );
      },
    );
  }
} 