import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/moto_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notificacoes_service.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O plugin `sqflite` só tem implementação nativa para Android e iOS.
  // Em Windows, Linux e macOS é preciso usar a implementação baseada em
  // FFI (`sqflite_common_ffi`), registrando-a como o databaseFactory
  // global antes de qualquer chamada a openDatabase.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('pt_BR', null);
  await NotificacoesService.inicializar();
  runApp(const MotoGastosApp());
}

class MotoGastosApp extends StatelessWidget {
  const MotoGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MotoProvider()..carregar()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..carregar()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, temaProvider, _) {
          return MaterialApp(
            title: 'Minha Moto - Gastos e Manutenção',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.claro(),
            darkTheme: AppTheme.escuro(),
            themeMode: temaProvider.modo,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
