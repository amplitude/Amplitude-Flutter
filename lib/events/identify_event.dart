import '../constants.dart';
import 'base_event.dart';

class IdentifyEvent extends BaseEvent {
  IdentifyEvent() : super(eventType: Constants.identifyEvent);
}
