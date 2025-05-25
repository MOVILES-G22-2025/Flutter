import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/payment_method.dart';

class PaymentMethodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener métodos de pago del usuario
  Stream<List<PaymentMethod>> getUserPaymentMethods(String userId) {
    try {
      return _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => PaymentMethod.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      print('Error al obtener métodos de pago: $e');
      rethrow;
    }
  }

  // Agregar nuevo método de pago
  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      await _firestore
          .collection('paymentMethods')
          .doc(paymentMethod.id)
          .set(paymentMethod.toMap());
    } catch (e) {
      print('Error al agregar método de pago: $e');
      throw Exception('No se pudo agregar el método de pago. Por favor, intenta de nuevo.');
    }
  }

  // Eliminar método de pago
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _firestore
          .collection('paymentMethods')
          .doc(paymentMethodId)
          .delete();
    } catch (e) {
      print('Error al eliminar método de pago: $e');
      throw Exception('No se pudo eliminar el método de pago. Por favor, intenta de nuevo.');
    }
  }

  // Establecer método de pago por defecto
  Future<void> setDefaultPaymentMethod(String paymentMethodId, String userId) async {
    try {
      final batch = _firestore.batch();
      final methods = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in methods.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      batch.update(
        _firestore.collection('paymentMethods').doc(paymentMethodId),
        {'isDefault': true},
      );

      await batch.commit();
    } catch (e) {
      print('Error al establecer método de pago por defecto: $e');
      throw Exception('No se pudo establecer el método de pago por defecto. Por favor, intenta de nuevo.');
    }
  }
} 