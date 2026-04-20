import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  static const Map<String, String> _testTokens = {
    '4242424242424242' : 'tok_visa',
    '1111111111111111' : 'tok_debit',
    '2222222222222222' : 'tok_mastercard',
    '3333333333333333' : 'tok_mastercard_debit',
    '4444444444444444' : 'tok_chargeDeclined',
    '5555555555555555' : 'tok_chargeInsufficientFunds',
  };

  static Future <Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll('', '');
    final token = _testTokens [cleanCard];

    if (token == null) {
      return {
        'success' : false,
        'error' : 'unknown test card. use 0000000000000000 (success)',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),

        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',


        },
        body: {
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_data[type]': 'card',
          'payment_method_types[]': 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data ['status'] == 'succeeded') {

        return {
          'success' : true,
          'id' : data ['id'],
          'amount' : data ['amount'] /100,
          'status' : data ['status'],
        };
      } else {
        return {
          'success' : false,
          'error' : data ['error']?['message']??'{Payment failed',
        };
      }
    } catch (e) {
      return {
        'success' : false,
        'error' : e.toString(),
      };
    }
  }
}