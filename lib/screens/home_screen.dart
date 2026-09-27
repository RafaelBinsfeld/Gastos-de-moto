import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/moto_provider.dart';

// Telas principais de abas
import 'relatorios_screen.dart';
import 'historico_screen.dart';
import 'motos_screen.dart';
import 'configuracoes_screen.dart';

// Formulários de cadastro
import 'abastecimento_form_screen.dart';
import 'manutencao_form_screen.dart';

import '../services/exportacao_service.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MotoProvider>(context, listen: false).carregarMotos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _abrirSeletorDeCores(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha a cor de destaque',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: themeProvider.availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      themeProvider.updateColor(color);
                      Navigator.pop(ctx);
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 24,
                      child: themeProvider.primaryColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _abrirOpcoesAdicionar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final motoProvider = Provider.of<MotoProvider>(context, listen: false);

    final int? motoId =
        motoProvider.motos.isNotEmpty ? motoProvider.motos.first.id : null;

    if (motoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cadastre uma moto na aba "Motos" antes de adicionar registros.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O que você deseja registrar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: themeProvider.primaryColor.withValues(alpha: 0.2),
                  child: Icon(Icons.local_gas_station,
                      color: themeProvider.primaryColor),
                ),
                title: const Text(
                  'Novo Abastecimento',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AbastecimentoFormScreen(motoId: motoId),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: themeProvider.primaryColor.withValues(alpha: 0.2),
                  child: Icon(Icons.build, color: themeProvider.primaryColor),
                ),
                title: const Text(
                  'Nova Manutenção',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManutencaoFormScreen(motoId: motoId),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportarBackup() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final abastecimentos = await db.query('abastecimentos');
      final manutencoes = await db.query('manutencoes');

      await ExportacaoService.exportarParaCSV(
        abastecimentos: abastecimentos,
        manutencoes: manutencoes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Minha Garagem',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens, color: themeProvider.primaryColor),
            tooltip: 'Alterar Cor',
            onPressed: () => _abrirSeletorDeCores(context),
          ),
          IconButton(
            icon: Icon(Icons.file_upload, color: themeProvider.primaryColor),
            tooltip: 'Exportar Backup',
            onPressed: _exportarBackup,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          RelatoriosScreen(),
          HistoricoScreen(),
          MotosScreen(),
          ConfiguracoesScreen(),
        ],
      ),
      // O botão flutuante só será exibido na aba de Relatórios (_currentIndex == 0)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.black,
              onPressed: () => _abrirOpcoesAdicionar(context),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: themeProvider.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.two_wheeler),
            label: 'Motos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}