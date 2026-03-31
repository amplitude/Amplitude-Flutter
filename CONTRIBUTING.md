# Contributing to the Amplitude SDK for Flutter

🎉 Thanks for your interest in contributing! 🎉

## Ramping Up

### Prerequisites

Make sure you have Flutter itself installed and the tools necessary for your desired platforms.

You can checkout the the official Flutter documentation on [getting started](https://flutter.dev/docs/get-started/install) for help.

## Setting Up and Running Examples

### Clone the repo

`git clone https://github.com/amplitude/Amplitude-Flutter`

### Try running the example Flutter Project

Checkout the [set up and editor](https://flutter.dev/docs/get-started/editor?tab=vscode) and [test drive](https://flutter.dev/docs/get-started/test-drive) sections of the official Flutter documentation on setting up your environment. 

You should then be able to run the Flutter project in `example/` which has the Amplitude Flutter SDK installed.

## Practices

### PR Commit Title Conventions

PR titles should follow [conventional commit standards](https://www.conventionalcommits.org/en/v1.0.0/). This helps automate the release process.

#### Commit Types

- **Special Case**: Any commit with `BREAKING CHANGES` in the body: Creates major release
- `feat(<optional scope>)`: New features (minimum minor release)
- `fix(<optional scope>)`: Bug fixes (minimum patch release)
- `perf(<optional scope>)`: Performance improvement
- `docs(<optional scope>)`: Documentation updates
- `test(<optional scope>)`: Test updates
- `refactor(<optional scope>)`: Code change that neither fixes a bug nor adds a feature
- `style(<optional scope>)`: Code style changes (e.g. formatting, commas, semi-colons)
- `build(<optional scope>)`: Changes that affect the build system or external dependencies (e.g. Yarn, Npm)
- `ci(<optional scope>)`: Changes to our CI configuration files and scripts
- `chore(<optional scope>)`: Other changes that don't modify src or test files
- `revert(<optional scope>)`: Revert commit

## Internal Amplitude Dev Contribution Notes

### Integrating a different Amplitude Flutter SDK
In Amplitude Flutter, we don't currently support the Amplitude Plugin architecture that we do on other platforms (e.g. iOS, Android, React Native, etc.). Because of this, we needed way for other Amplitude Flutter SDK's to hook into the underlying `Amplitude` instance from a native context to be able to use Amplitude plugins.

To enable this, the `amplitude_flutter` plugin exposes `getAmplitudeInstanceById` on each native platform, at the Flutter native layer, so that
other Amplitude Flutter plugins (e.g. [Amplitude Engagement](https://pub.dev/packages/amplitude_engagement_flutter)) can obtain the underlying
native `Amplitude` instance by its `configuration.instanceName`.

Then on each native platform, once we have obtained the underlying `Amplitude` instance, we can then add the Amplitude plugin to the instance.

For example, on iOS, we can add the Amplitude Engagement plugin to the instance by calling for example: `amplitude.add(engagement.getPlugin())`.
