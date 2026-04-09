/// Base State class for all BLoC states
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

enum StateStatus { initial, loading, success, failure, loadingMore }

abstract class BaseState extends Equatable {
  final StateStatus status;
  final Failure? failure;
  final String? message;

  const BaseState({
    this.status = StateStatus.initial,
    this.failure,
    this.message,
  });

  bool get isInitial => status == StateStatus.initial;
  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isFailure => status == StateStatus.failure;
  bool get isLoadingMore => status == StateStatus.loadingMore;

  @override
  List<Object?> get props => [status, failure, message];
}

/// Generic data state for simple use cases
class DataState<T> extends BaseState {
  final T? data;
  final bool hasReachedMax;
  final int currentPage;

  const DataState({
    super.status,
    super.failure,
    super.message,
    this.data,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  DataState<T> copyWith({
    StateStatus? status,
    Failure? failure,
    String? message,
    T? data,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return DataState<T>(
      status: status ?? this.status,
      failure: failure,
      message: message ?? this.message,
      data: data ?? this.data,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    failure,
    message,
    data,
    hasReachedMax,
    currentPage,
  ];
}

/// State for list data with pagination
class ListState<T> extends BaseState {
  final List<T> items;
  final bool hasReachedMax;
  final int currentPage;
  final int totalItems;

  const ListState({
    super.status,
    super.failure,
    super.message,
    this.items = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalItems = 0,
  });

  ListState<T> copyWith({
    StateStatus? status,
    Failure? failure,
    String? message,
    List<T>? items,
    bool? hasReachedMax,
    int? currentPage,
    int? totalItems,
  }) {
    return ListState<T>(
      status: status ?? this.status,
      failure: failure,
      message: message ?? this.message,
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  List<Object?> get props => [
    status,
    failure,
    message,
    items,
    hasReachedMax,
    currentPage,
    totalItems,
  ];
}
