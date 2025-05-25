import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/payment_method.dart';
import '../../../data/services/payment_method_service.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String currentUserId;

  const PaymentMethodsScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Métodos de Pago'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentMethodScreen(
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: PaymentMethodService().getUserPaymentMethods(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar métodos de pago',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Por favor, verifica tu conexión e intenta de nuevo',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Forzar reconstrucción
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final paymentMethods = snapshot.data!;

          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No tienes métodos de pago agregados'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPaymentMethodScreen(
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    child: Text('Agregar método de pago'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              return PaymentMethodCard(
                paymentMethod: method,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Eliminar método de pago'),
                      content: Text('¿Estás seguro de eliminar este método de pago?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            PaymentMethodService()
                                .deletePaymentMethod(method.id);
                            Navigator.pop(context);
                          },
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
                onSetDefault: () {
                  PaymentMethodService()
                      .setDefaultPaymentMethod(method.id, method.userId);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const PaymentMethodCard({
    Key? key,
    required this.paymentMethod,
    required this.onDelete,
    required this.onSetDefault,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getPaymentMethodIcon(paymentMethod.type),
          color: Theme.of(context).primaryColor,
        ),
        title: Text(_getPaymentMethodTitle(paymentMethod)),
        subtitle: Text(paymentMethod.accountNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!paymentMethod.isDefault)
              IconButton(
                icon: Icon(Icons.star_border),
                onPressed: onSetDefault,
                tooltip: 'Establecer como predeterminado',
              ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'nequi':
        return Icons.phone_android;
      case 'daviplata':
        return Icons.phone_android;
      default:
        return Icons.payment;
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