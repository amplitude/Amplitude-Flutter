#!/usr/bin/env python3
"""Run the real Swift adapter's invalid-init contract tests on a macOS host.

Requires Flutter macOS artifacts and example/ios's actual installed SDK Pods.
All compiler outputs live in a temporary directory; no native SDK is constructed.
"""
import argparse
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--checkout', type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument('--pods-root', type=Path)
    parser.add_argument('--flutter-root', type=Path)
    parser.add_argument('--test-source', type=Path)
    options = parser.parse_args()
    if platform.system() != 'Darwin':
        parser.error('This native test requires macOS')

    checkout = options.checkout.resolve()
    pods = options.pods_root or checkout / 'example/ios/Pods'
    flutter_command = shutil.which('flutter')
    if options.flutter_root:
        flutter_root = options.flutter_root
    elif flutter_command:
        flutter_root = Path(flutter_command).resolve().parents[1]
    else:
        parser.error('Flutter must be on PATH or supplied with --flutter-root')
    flutter_framework = flutter_root / (
        'bin/cache/artifacts/engine/darwin-x64/'
        'FlutterMacOS.xcframework/macos-arm64_x86_64'
    )
    core_framework = pods / (
        'AmplitudeCore/AmplitudeCore.xcframework/macos-arm64_x86_64'
    )
    connector_sources = sorted(
        (pods / 'AnalyticsConnector/Sources/AnalyticsConnector').rglob('*.swift')
    )
    sdk_sources = sorted((pods / 'AmplitudeSwift/Sources/Amplitude').rglob('*.swift'))
    adapter_sources = sorted(
        (checkout / 'darwin/amplitude_flutter/Sources/amplitude_flutter').glob('*.swift')
    )
    test_source = options.test_source or checkout / 'test/native/swift_init/main.swift'
    for framework in (
        flutter_framework / 'FlutterMacOS.framework',
        core_framework / 'AmplitudeCore.framework',
    ):
        if not framework.exists():
            parser.error('Required real framework is missing: ' + str(framework))
    if not connector_sources or not sdk_sources or not adapter_sources or not test_source.exists():
        parser.error('Prepare real example/ios Pods and provide the adapter/test sources')

    with tempfile.TemporaryDirectory(prefix='amplitude-swift-init-') as temporary:
        build = Path(temporary)
        common = [
            'swiftc', '-swift-version', '5',
            '-target', platform.machine() + '-apple-macosx10.15',
            '-module-cache-path', str(build / 'ModuleCache'),
        ]
        subprocess.run(
            common + [
                '-emit-library', '-emit-module', '-module-name', 'AnalyticsConnector',
                '-emit-module-path', str(build / 'AnalyticsConnector.swiftmodule'),
                '-o', str(build / 'libAnalyticsConnector.dylib'),
            ] + [str(source) for source in connector_sources],
            check=True,
        )
        subprocess.run(
            common + [
                '-emit-library', '-emit-module', '-module-name', 'AmplitudeSwift',
                '-I', str(build), '-L', str(build), '-lAnalyticsConnector',
                '-F', str(core_framework), '-framework', 'AmplitudeCore',
                '-Xlinker', '-rpath', '-Xlinker', str(core_framework),
                '-emit-module-path', str(build / 'AmplitudeSwift.swiftmodule'),
                '-o', str(build / 'libAmplitudeSwift.dylib'),
            ] + [str(source) for source in sdk_sources],
            check=True,
        )
        binary = build / 'swift-init-tests'
        subprocess.run(
            common + [
                '-I', str(build), '-L', str(build),
                '-lAnalyticsConnector', '-lAmplitudeSwift',
                '-F', str(core_framework), '-F', str(flutter_framework),
                '-framework', 'AmplitudeCore', '-framework', 'FlutterMacOS',
                '-Xlinker', '-rpath', '-Xlinker', str(core_framework),
                '-Xlinker', '-rpath', '-Xlinker', str(flutter_framework),
                '-o', str(binary),
            ] + [str(source) for source in adapter_sources] + [str(test_source)],
            check=True,
        )
        return subprocess.run([str(binary)]).returncode


if __name__ == '__main__':
    raise SystemExit(main())
