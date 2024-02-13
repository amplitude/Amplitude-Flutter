import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/base_event.dart';

class RevenueEvent extends BaseEvent {
  RevenueEvent() : super(eventType: Constants.revenue_event);
}
