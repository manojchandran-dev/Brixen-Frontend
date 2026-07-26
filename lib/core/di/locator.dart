import 'package:get_it/get_it.dart';
import '../theme/theme_cubit.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
}
