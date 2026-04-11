import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/purchase_request/domain/repositories/purchase_request_repository.dart';
import '../../features/purchase_request/data/repositories/purchase_request_repository_impl.dart';
import '../../features/expense_request/domain/repositories/expense_request_repository.dart';
import '../../features/expense_request/data/repositories/expense_request_repository_impl.dart';
import '../../features/purchase_request/presentation/cubit/purchase_request_cubit.dart';
import '../../features/expense_request/presentation/cubit/expense_request_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Dashboard
  // Cubit
  sl.registerFactory(() => DashboardCubit(sl()));
  
  // Repositories
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );

  //! Features - Procurement
  sl.registerLazySingleton<PurchaseRequestRepository>(
    () => PurchaseRequestRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ExpenseRequestRepository>(
    () => ExpenseRequestRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory(() => PurchaseRequestCubit(sl()));
  sl.registerFactory(() => ExpenseRequestCubit(sl()));

  //! Core
  sl.registerLazySingleton(() => Supabase.instance.client);
  
  // More features can be added here...
}
