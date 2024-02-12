import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/base_event.dart';

class IdentifyEvent extends BaseEvent {
  IdentifyEvent() : super(eventType: Constants.identify_event);
}
