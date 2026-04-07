import 'package:flutter/material.dart';

import 'my_app.dart';

void main() => runApp(
      const MyApp(
        String.fromEnvironment('AMPLITUDE_API_KEY', defaultValue: 'API_KEY'),
      ),
    );
