# amplitude_flutter_example

Demonstrates how to use the amplitude flutter plugin.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.io/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.io/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.io/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Run the example
Assuming you have Flutter setup on your machine.

Update your Amplitude API key in `lib/main.dart`.

### Android & iOS
Open the emulator you want to test on (Android, iOS)
```shell
flutter run
```

### Browser
```shell
flutter run -d chrome
```
In some cases (e.g. Chrome with forced sign-in), above command may not work well.
Use the below command to start the server, then follow the printed link in console.
```shell
flutter run -d web-server --web-port=5000 --web-enable-expression-evaluation
```
