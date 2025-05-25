import 'package:flutter/material.dart';
import '../../../domain/models/payment_method.dart';
import '../../../data/services/payment_method_service.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final String currentUserId;

  const AddPaymentMethodScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _AddPaymentMethodScreenState createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'bank';
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Método de Pago'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Selector de tipo de cuenta
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo de cuenta',
              ),
              items: [
                DropdownMenuItem(
                  value: 'bank',
                  child: Text('Cuenta Bancaria'),
                ),
                DropdownMenuItem(
                  value: 'nequi',
                  child: Text('Nequi'),
                ),
                DropdownMenuItem(
                  value: 'daviplata',
                  child: Text('DaviPlata'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            SizedBox(height: 16),

            // Número de cuenta
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Número de cuenta',
                hintText: 'Ingresa el número de cuenta',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el número de cuenta';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Nombre del titular
            TextFormField(
              controller: _accountHolderController,
              decoration: InputDecoration(
                labelText: 'Nombre del titular',
                hintText: 'Ingresa el nombre del titular',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre del titular';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Nombre del banco (solo para cuentas bancarias)
            if (_selectedType == 'bank')
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del banco',
                  hintText: 'Ingresa el nombre del banco',
                ),
                validator: (value) {
                  if (_selectedType == 'bank' && (value == null || value.isEmpty)) {
                    return 'Por favor ingresa el nombre del banco';
                  }
                  return null;
                },
              ),

            SizedBox(height: 24),

            // Botón para guardar
            ElevatedButton(
              onPressed: _savePaymentMethod,
              child: Text('Guardar método de pago'),
            ),
          ],
        ),
      ),
    );
  }

  void _savePaymentMethod() {
    if (_formKey.currentState!.validate()) {
      final paymentMethod = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUserId,
        type: _selectedType,
        accountNumber: _accountNumberController.text,
        accountHolder: _accountHolderController.text,
        bankName: _bankNameController.text,
        createdAt: DateTime.now(),
      );

      PaymentMethodService().addPaymentMethod(paymentMethod);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }
} 