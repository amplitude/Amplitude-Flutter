import 'package:amplitude_flutter/constants.dart';
import 'base_event.dart';

class GroupIdentifyEvent extends BaseEvent {
  GroupIdentifyEvent() : super(eventType: Constants.group_identify_event);
}
