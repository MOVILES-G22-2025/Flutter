import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarVendedor extends StatelessWidget {
  final String? urlFoto;
  final String nombre;

  const AvatarVendedor({Key? key, this.urlFoto, required this.nombre}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (urlFoto != null && urlFoto!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: CachedNetworkImageProvider(urlFoto!),
      );
    }
    // Si no hay foto, iniciales o ícono
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: 40, color: Colors.grey[700]),
    );
  }
}
