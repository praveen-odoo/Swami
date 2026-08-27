import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/home_service.dart';
import 'providers.dart';

final homeServiceProvider = Provider((ref) => HomeService(ref.watch(apiServiceProvider)));

class HomeDataState {
  final bool isLoading;
  final ApiHomeData? data;
  final String? error;

  HomeDataState({this.isLoading = false, this.data, this.error});

  HomeDataState copyWith({bool? isLoading, ApiHomeData? data, String? error}) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class HomeNotifier extends Notifier<HomeDataState> {
  @override
  HomeDataState build() {
    // Re-fetch data automatically when the service (and its language setting) changes
    ref.listen(homeServiceProvider, (previous, next) {
      debugPrint('🏠 HomeNotifier: Locale/Service changed, re-fetching data...');
      load();
    });
    
    return HomeDataState();
  }

  HomeService get _service => ref.read(homeServiceProvider);

  Future<void> load() async {
    debugPrint('🏠 HomeNotifier: load() triggered');
    state = state.copyWith(isLoading: true);
    try {
      final homeData = await _service.fetchHomeData();
      debugPrint('🏠 HomeNotifier: Data loaded successfully');
      state = state.copyWith(isLoading: false, data: homeData);
    } catch (e) {
      debugPrint('🏠 HomeNotifier ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeDataState>(HomeNotifier.new);
