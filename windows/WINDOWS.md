# Windows Platform Support

This directory contains the native C++ implementation of the Amplitude Flutter plugin for Windows. Since no official Amplitude C/C++ SDK exists, this plugin implements the complete Amplitude analytics engine from scratch in C++: event queuing, persistent storage, HTTP transport, session management, device info collection, and app lifecycle tracking.

## Architecture

```
windows/
├── CMakeLists.txt                   Build config (nlohmann/json via FetchContent, WinHTTP, BCrypt)
├── include/amplitude_flutter/
│   └── amplitude_flutter_plugin_c_api.h   C ABI export header
├── amplitude_flutter_plugin_c_api.cpp     C → C++ registration bridge
├── amplitude_flutter_plugin.h/cpp         Method channel dispatch + WM_ACTIVATEAPP lifecycle hook
├── amplitude_instance.h/cpp               Core engine: config, state, enrichment, sessions
├── event_queue.h/cpp                      Persistent queue, batch flush, background timer thread
├── http_transport.h/cpp                   WinHTTP POST to HTTP V2 / Batch API with retry
├── device_info.h/cpp                      OS version (RtlGetVersion), device model/manufacturer (registry)
├── storage.h/cpp                          Atomic JSON file persistence (%LOCALAPPDATA%)
└── uuid.h                                 UUID v4 + insert_id generation (BCryptGenRandom)
```

### How it works

The Dart SDK (`lib/amplitude.dart`) sends method calls over a `MethodChannel` named `"amplitude_flutter"`. On iOS/macOS, Swift handles these calls via AmplitudeSwift. On Android, Kotlin handles them via Amplitude-Kotlin. On Windows, this C++ plugin handles them by:

1. **Receiving** `flutter::EncodableMap` arguments from the method channel
2. **Converting** them to `nlohmann::json` for internal processing
3. **Enriching** each event with device info, session ID, insert ID, library string, and timestamps
4. **Queuing** events in an in-memory vector backed by persistent JSON file storage
5. **Flushing** events via WinHTTP POST to the Amplitude HTTP V2 or Batch API
6. **Retrying** failed sends with exponential backoff (1s, 2s, 4s... up to `flushMaxRetries`)

A background `std::thread` fires periodic flushes every `flushIntervalMillis` milliseconds. The queue also auto-flushes when it reaches `flushQueueSize` events.

### Persistence

All persistent state is stored under `%LOCALAPPDATA%\amplitude\<instanceName>\`:

| File | Contents |
|------|----------|
| `identity.json` | `device_id`, `user_id`, `session_id`, `last_event_time` |
| `events.json` | Array of pending events (crash recovery) |

Writes use atomic temp-file-then-rename to prevent corruption.

### Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| [nlohmann/json](https://github.com/nlohmann/json) v3.11.3 | Header-only (FetchContent) | JSON serialization |
| `winhttp.lib` | Windows system | HTTPS transport |
| `bcrypt.lib` | Windows system | Cryptographic random (UUID, insert_id) |

No external runtime dependencies. The nlohmann/json header is fetched at build time via CMake `FetchContent` and statically compiled in.

## Method Channel Parity

All 14 method channel calls are implemented with identical semantics to iOS/Android/macOS:

| Method | Windows | iOS | macOS | Android | Web |
|--------|---------|-----|-------|---------|-----|
| `init` | C++ engine + persistent storage | AmplitudeSwift | AmplitudeSwift | Amplitude-Kotlin | Browser SDK |
| `track` | Enrich → queue → HTTP V2 | Native SDK | Native SDK | Native SDK | JS SDK |
| `identify` | Routes through `track` | Native SDK | Native SDK | Native SDK | JS SDK |
| `groupIdentify` | Routes through `track` | Native SDK | Native SDK | Native SDK | JS SDK |
| `setGroup` | Routes through `track` | Native SDK | Native SDK | Native SDK | JS SDK |
| `revenue` | Routes through `track` | Native SDK | Native SDK | Native SDK | JS SDK |
| `getUserId` | Returns from memory | Native SDK | Native SDK | Native SDK | JS SDK |
| `setUserId` | Memory + persist | Native SDK | Native SDK | Native SDK | JS SDK |
| `getDeviceId` | Returns from memory | Native SDK | Native SDK | Native SDK | JS SDK |
| `setDeviceId` | Memory + persist | Native SDK | Native SDK | Native SDK | JS SDK |
| `getSessionId` | Returns from memory | Native SDK | Native SDK | Native SDK | JS SDK |
| `reset` | Clear userId, new deviceId | Native SDK | Native SDK | Native SDK | JS SDK |
| `flush` | Force HTTP send | Native SDK | Native SDK | Native SDK | JS SDK |
| `setOptOut` | In-memory flag | Not impl | Not impl | Not impl | JS SDK |

## Configuration Options

| Option | Windows | iOS/macOS | Android | Web | Notes |
|--------|---------|-----------|---------|-----|-------|
| `apiKey` | Yes | Yes | Yes | Yes | Required on all platforms |
| `flushQueueSize` | Yes | Yes | Yes | Yes | Default: 30 |
| `flushIntervalMillis` | Yes | Yes | Yes | Yes | Default: 30000 |
| `instanceName` | Yes | Yes | Yes | Yes | Multi-instance support |
| `optOut` | Yes | Yes | Yes | Yes | |
| `logLevel` | Parsed | Yes | Yes | Yes | Windows accepts but does not emit logs |
| `minIdLength` | Parsed | Yes | Yes | Yes | |
| `partnerId` | Yes | Yes | Yes | Yes | |
| `flushMaxRetries` | Yes | Yes | Yes | Yes | Default: 5 |
| `useBatch` | Yes | Yes | Yes | Yes | Selects `/batch` vs `/2/httpapi` |
| `serverZone` | Yes | Yes | Yes | Yes | US or EU endpoint |
| `serverUrl` | Yes | Yes | Yes | Yes | Custom endpoint override |
| `minTimeBetweenSessionsMillis` | Yes | Yes | Yes | Yes | Default: 300000 (5 min) |
| `enableCoppaControl` | Yes | Yes | Yes | No | Strips IP, disables geo fields |
| `flushEventsOnClose` | Yes | Yes | Yes | No | Flushes on pause/destroy |
| `defaultTracking.sessions` | Yes | Yes | Yes | Yes | Start/End Session events |
| `defaultTracking.appLifecycles` | Yes | Yes | Yes | No | Opened/Backgrounded events |
| `trackingOptions.*` | Yes | Yes | Yes | Partial | Controls which fields are sent |
| `identifyBatchIntervalMillis` | No | Yes | Yes | No | Not yet implemented |
| `migrateLegacyData` | No | Yes | Yes | No | Not applicable (no legacy data) |
| `locationListening` | No | No | No | Yes | Android-specific |
| `useAdvertisingIdForDeviceId` | No | No | No | Yes | Android-specific |
| `useAppSetIdForDeviceId` | No | No | No | Yes | Android-specific |
| `autocapture.*` | No | No | No | No | Web-specific |
| `cookieOptions` | No | No | No | No | Web-specific |
| `identityStorage` | No | No | No | No | Web-specific |

## Default Tracking Events

| Event | Windows | iOS | macOS | Android | Web |
|-------|---------|-----|-------|---------|-----|
| `[Amplitude] Start Session` | Yes | Yes | Yes | Yes | Yes |
| `[Amplitude] End Session` | Yes | Yes | Yes | Yes | Yes |
| `[Amplitude] Application Opened` | Yes | Yes | Yes | Yes | No |
| `[Amplitude] Application Backgrounded` | Yes | Yes | Yes | Yes | No |
| `[Amplitude] Application Installed` | No | Yes | Yes | Yes | No |
| `[Amplitude] Application Updated` | No | Yes | Yes | Yes | No |
| `[Amplitude] Deep Link Opened` | No | No | No | Yes | No |

**Windows lifecycle detection** uses `WM_ACTIVATEAPP` via `RegisterTopLevelWindowProcDelegate`. The window gaining focus triggers `OnAppLifecycleResumed` (emitting Application Opened with `from_background: true`). Losing focus triggers `OnAppLifecyclePaused` (emitting Application Backgrounded and flushing the queue).

Application Installed/Updated are not tracked on Windows because there is no standard mechanism to detect first-run vs update on Windows desktop apps.

## Device Properties

| Property | Windows Source | iOS | Android | macOS | Web |
|----------|---------------|-----|---------|-------|-----|
| `platform` | `"Windows"` | `"iOS"` | `"Android"` | `"macOS"` | `"Web"` |
| `os_name` | `"Windows"` | `"ios"` | `"Android"` | `"macos"` | Browser UA |
| `os_version` | `RtlGetVersion()` e.g. `"10.0.26200"` | System | System | System | Browser UA |
| `device_manufacturer` | Registry `SystemManufacturer` | System | System | `"Apple"` | Browser UA |
| `device_model` | Registry `SystemProductName` | System | System | Model ID | Browser UA |
| `device_brand` | Same as manufacturer | `"Apple"` | System | `"Apple"` | Browser UA |
| `language` | `GetUserDefaultLocaleName()` | System | System | System | `navigator.language` |
| `carrier` | `"unknown"` (desktop) | Telephony | Telephony | `"unknown"` | N/A |
| `device_id` | Generated UUID v4, persisted | IDFV | Random UUID | UUID | Cookie/LS |
| `insert_id` | `"{timestamp_ms}-{random_hex}"` | SDK-generated | SDK-generated | SDK-generated | SDK-generated |

**Registry paths** for device info:
- Manufacturer: `HKLM\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer`
- Model: `HKLM\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName`

## Known Limitations

### `platform` field shows `(none)` in Amplitude groupBy

The Windows plugin sends events via the Amplitude HTTP V2 API. The `platform` core property is server-computed by Amplitude and **cannot be set via the HTTP API** — it is always overwritten to `(none)` regardless of what value the client sends. This is an Amplitude server-side restriction that affects all HTTP-based Amplitude clients (including Node.js, Python, Java server SDKs).

The iOS, Android, and macOS plugins do not have this limitation because they use native Amplitude SDKs (AmplitudeSwift, Amplitude-Kotlin) which communicate via a different protocol.

**Workaround**: Filter Windows events by `os_name = "Windows"` or by a custom event property instead of the `platform` field.

### No identify batching

The native iOS/Android SDKs batch consecutive `identify` calls via `identifyBatchIntervalMillis` to reduce API calls. The Windows plugin sends each identify immediately via `track()`. For most use cases this is not noticeable, but apps that send many rapid identify calls may see slightly higher API usage.

### No Application Installed / Application Updated events

There is no standard mechanism on Windows to detect whether the app is being launched for the first time or has been updated. These events are skipped on Windows.

## Build Requirements

- **CMake**: >= 3.14
- **C++ Standard**: C++17 (set by `apply_standard_settings`)
- **Compiler**: MSVC (Visual Studio 2019+), Clang-cl, or MinGW-w64
- **Windows SDK**: Windows 10+
- **Internet**: Required on first build to fetch nlohmann/json via FetchContent (cached afterwards)

## Thread Safety

The plugin runs on Flutter's platform thread. Event enrichment and queue push happen synchronously on this thread. HTTP transport runs on a background `std::thread` managed by `EventQueue`. A `std::mutex` protects all shared state. The background thread is cleanly shut down via `std::condition_variable` + stop flag + `join()` on destruction.
