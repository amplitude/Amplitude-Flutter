import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';

class RevenueForm extends StatefulWidget {
  @override
  _RevenueFormState createState() => _RevenueFormState();
}

class _RevenueFormState extends State<RevenueForm> {
  final TextEditingController productId =
      TextEditingController(text: 'specialProduct');
  final TextEditingController price = TextEditingController(text: '41.23');
  final TextEditingController quantity = TextEditingController(text: '2');

  void onPress() {
    if (productId.text.isNotEmpty &&
        double.tryParse(price.text) != null &&
        int.tryParse(quantity.text) != null) {
      AppState.of(context)
        ..analytics.logRevenue(
          productId.text,
          int.tryParse(quantity.text)!,
          double.tryParse(price.text)!,
        )
        ..setMessage('Revenue Sent.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration dec = InputDecoration()
      ..applyDefaults(Theme.of(context).inputDecorationTheme);

    const Widget vertSpace = SizedBox(height: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Revenue', style: Theme.of(context).textTheme.headline5),
        const SizedBox(height: 10),
        TextField(
            decoration: dec.copyWith(labelText: 'Product Id'),
            controller: productId),
        vertSpace,
        TextField(inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[\d\.]'))
        ], decoration: dec.copyWith(labelText: 'Price'), controller: price),
        vertSpace,
        TextField(
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'\d'))
            ],
            decoration: dec.copyWith(labelText: 'Quantity'),
            controller: quantity),
        ElevatedButton(child: const Text('Send Revenue'), onPressed: onPress)
      ],
    );
  }
}
