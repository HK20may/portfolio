import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../state/console_cubit.dart';
import '../state/navigation_cubit.dart';
import '../state/palette_cubit.dart';
import '../state/scroll_intent_cubit.dart';
import '../shared/cursor/cursor_scope.dart';
import 'app_shell.dart';
import 'router.dart';

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => ScrollIntentCubit()),
        BlocProvider(create: (_) => ConsoleCubit()),
        BlocProvider(create: (_) => PaletteCubit()),
      ],
      child: MaterialApp.router(
        title: 'Harshit Kumawat — Flutter Developer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
        builder: (context, child) => CursorScope(
          child: AppShell(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
