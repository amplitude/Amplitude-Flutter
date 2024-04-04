import '../constants.dart';
import 'base_event.dart';

class GroupIdentifyEvent extends BaseEvent {
  GroupIdentifyEvent() : super(eventType: Constants.groupIdentifyEvent);
}
