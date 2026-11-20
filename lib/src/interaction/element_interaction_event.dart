import '../../events/base_event.dart';
import 'element_interaction_event_data.dart';

/// `[Amplitude] Element Interacted`, sent for a tap on a control, as iOS
/// and Android send it for theirs.
class ElementInteractionEvent extends BaseEvent {
  /// [timestamp] is when the tap happened: the event may wait for the SDK
  /// to finish initializing, and the platform SDK would otherwise date it
  /// when it is sent.
  ElementInteractionEvent(
    ElementInteractionEventData data, {
    required int timestamp,
  }) : super(
          _Keys.eventType,
          timestamp: timestamp,
          eventProperties: {
            // Both native SDKs send touch for a button press (Q3).
            _Keys.action: 'touch',
            _Keys.targetSource: 'Flutter',
            _Keys.targetViewClass: data.targetViewClass,
            // Values that aren't set are left out; set ones are sent as they
            // are, even when empty, as iOS and Android do.
            if (data.targetText != null) _Keys.targetText: data.targetText,
            if (data.accessibilityLabel != null)
              _Keys.accessibilityLabel: data.accessibilityLabel,
            if (data.accessibilityIdentifier != null)
              _Keys.accessibilityIdentifier: data.accessibilityIdentifier,
            if (data.hierarchy != null) _Keys.hierarchy: data.hierarchy,
            if (data.screenName != null) _Keys.screenName: data.screenName,
          },
        );
}

/// The event and property names. iOS's names where iOS has one; pending
/// review of the cross-SDK key mapping.
class _Keys {
  static const eventType = '[Amplitude] Element Interacted';
  static const action = '[Amplitude] Action';
  static const targetSource = '[Amplitude] Target Source';
  static const targetViewClass = '[Amplitude] Target View Class';
  static const targetText = '[Amplitude] Target Text';
  static const accessibilityLabel = '[Amplitude] Target Accessibility Label';
  static const accessibilityIdentifier =
      '[Amplitude] Target Accessibility Identifier';
  static const hierarchy = '[Amplitude] Hierarchy';
  static const screenName = '[Amplitude] Screen Name';
}
