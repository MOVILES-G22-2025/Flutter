import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/models/payment_method.dart';
import '../../../data/services/payment_method_service.dart';
import '../../../core/services/custom_cache_manager.dart';
import '../../../constants.dart';

class SellerProfilePage extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerImageUrl;

  const SellerProfilePage({
    Key? key,
    required this.sellerId,
    required this.sellerName,
    this.sellerImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary0),
        title: Text(
          'Perfil del Vendedor',
          style: TextStyle(
            color: AppColors.primary0,
            fontFamily: 'Cabin',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del vendedor
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary30,
                      child: sellerImageUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: sellerImageUrl!,
                                cacheManager: CustomCacheManager.instance,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => CircularProgressIndicator(
                                  color: AppColors.primary30,
                                ),
                                errorWidget: (_, __, ___) =>
                                    Icon(Icons.person, size: 50, color: Colors.white),
                              ),
                            )
                          : Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sellerName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cabin',
                            color: AppColors.primary0,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary30.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Vendedor Verificado',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary30,
                              fontFamily: 'Cabin',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Métodos de pago
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        color: AppColors.primary30,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Métodos de Pago',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cabin',
                          color: AppColors.primary0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  StreamBuilder<List<PaymentMethod>>(
                    stream: PaymentMethodService().getUserPaymentMethods(sellerId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorState();
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingState();
                      }

                      final paymentMethods = snapshot.data!;

                      if (paymentMethods.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: paymentMethods.length,
                        itemBuilder: (context, index) {
                          final method = paymentMethods[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // TODO: Implementar vista detallada del método de pago
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: _getPaymentMethodColor(method.type),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: _getPaymentMethodIcon(method.type),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getPaymentMethodTitle(method),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cabin',
                                                color: AppColors.primary0,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              method.accountNumber,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontFamily: 'Cabin',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (method.isDefault)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary30.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: AppColors.primary30,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Predeterminado',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primary30,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cabin',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.primary30,
          ),
          SizedBox(height: 16),
          Text(
            'No se pudieron cargar los métodos de pago',
            style: TextStyle(
              color: AppColors.primary0,
              fontSize: 16,
              fontFamily: 'Cabin',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Por favor, intenta más tarde',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Cabin',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary30,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando métodos de pago...',
            style: TextStyle(
              color: AppColors.primary0,
              fontSize: 16,
              fontFamily: 'Cabin',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 48,
            color: AppColors.primary30,
          ),
          SizedBox(height: 16),
          Text(
            'No hay métodos de pago disponibles',
            style: TextStyle(
              color: AppColors.primary0,
              fontSize: 16,
              fontFamily: 'Cabin',
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPaymentMethodIcon(String type) {
    switch (type) {
      case 'nequi':
        return Image.asset(
          'assets/images/nequi_logo.png',
          width: 32,
          height: 32,
        );
      case 'daviplata':
        return Image.asset(
          'assets/images/daviplata_logo.png',
          width: 32,
          height: 32,
        );
      case 'bank':
        return Icon(
          Icons.account_balance,
          color: Colors.white,
          size: 32,
        );
      default:
        return Icon(
          Icons.payment,
          color: Colors.white,
          size: 32,
        );
    }
  }

  Color _getPaymentMethodColor(String type) {
    switch (type) {
      case 'nequi':
        return Color(0xFF00D1B2); // Color oficial de Nequi
      case 'daviplata':
        return Color(0xFFE30613); // Color oficial de DaviPlata
      case 'bank':
        return AppColors.primary30;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodTitle(PaymentMethod method) {
    switch (method.type) {
      case 'bank':
        return '${method.bankName} - ${method.accountHolder}';
      case 'nequi':
        return 'Nequi - ${method.accountHolder}';
      case 'daviplata':
        return 'DaviPlata - ${method.accountHolder}';
      default:
        return method.accountHolder;
    }
  }
} 