/// Base BLoC class with common functionality
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_event.dart';
import 'base_state.dart';

abstract class BaseBloc<E extends BaseEvent, S extends BaseState>
    extends Bloc<E, S> {
  BaseBloc(super.initialState) {
    _registerEventHandlers();
  }

  /// Override this to register event handlers
  void _registerEventHandlers() {}

  /// Helper method to emit loading state
  void emitLoading(Emitter<S> emit, S state) {
    emit(state);
  }

  /// Helper method to emit success state
  void emitSuccess(Emitter<S> emit, S state) {
    emit(state);
  }

  /// Helper method to emit failure state
  void emitFailure(Emitter<S> emit, S state) {
    emit(state);
  }

  /// Debounce transformer for search/filter operations
  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) =>
        events.debounceTime(duration).asyncExpand(mapper);
  }

  /// Throttle transformer for scroll/button operations
  EventTransformer<T> throttle<T>(Duration duration) {
    return (events, mapper) =>
        events.throttleTime(duration).asyncExpand(mapper);
  }
}

/// Extension to add debounce and throttle to streams
extension StreamDebounce<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) {
    Timer? timer;
    late T latestValue;
    var hasValue = false;

    return transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          latestValue = data;
          hasValue = true;
          timer?.cancel();
          timer = Timer(duration, () {
            if (hasValue) {
              sink.add(latestValue);
              hasValue = false;
            }
          });
        },
        handleDone: (sink) {
          timer?.cancel();
          if (hasValue) {
            sink.add(latestValue);
          }
          sink.close();
        },
      ),
    );
  }

  Stream<T> throttleTime(Duration duration) {
    Timer? timer;
    var canEmit = true;

    return transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          if (canEmit) {
            sink.add(data);
            canEmit = false;
            timer = Timer(duration, () {
              canEmit = true;
            });
          }
        },
        handleDone: (sink) {
          timer?.cancel();
          sink.close();
        },
      ),
    );
  }
}

/// Mixin for BLoCs that need periodic refresh
mixin RefreshableBlocMixin<E extends BaseEvent, S extends BaseState>
    on Bloc<E, S> {
  Timer? _refreshTimer;
  Duration get refreshInterval => const Duration(minutes: 5);

  void startPeriodicRefresh(E refreshEvent) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      add(refreshEvent);
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Future<void> close() {
    stopPeriodicRefresh();
    return super.close();
  }
}

/// Mixin for BLoCs that support pagination
mixin PaginationBlocMixin<E extends BaseEvent, S extends BaseState>
    on Bloc<E, S> {
  int currentPage = 1;
  bool hasReachedMax = false;
  static const int pageSize = 20;

  void resetPagination() {
    currentPage = 1;
    hasReachedMax = false;
  }

  void incrementPage() {
    currentPage++;
  }
}
