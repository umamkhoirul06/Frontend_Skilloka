/// Base Event class for all BLoC events
import 'package:equatable/equatable.dart';

abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

/// Event for initial loading
class InitialLoadEvent extends BaseEvent {
  const InitialLoadEvent();
}

/// Event for refreshing data
class RefreshEvent extends BaseEvent {
  const RefreshEvent();
}

/// Event for loading more data (pagination)
class LoadMoreEvent extends BaseEvent {
  final int page;

  const LoadMoreEvent({required this.page});

  @override
  List<Object?> get props => [page];
}

/// Event for retrying failed operation
class RetryEvent extends BaseEvent {
  const RetryEvent();
}
