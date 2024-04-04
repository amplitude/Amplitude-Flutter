import '../constants.dart';
import 'base_event.dart';

class RevenueEvent extends BaseEvent {
  RevenueEvent() : super(eventType: Constants.revenue_event);
}
