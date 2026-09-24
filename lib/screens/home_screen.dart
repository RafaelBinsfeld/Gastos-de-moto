import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Substitua essa variável pelo nome vindo do banco de dados quando quiser dinamizar
  final String _nomeMoto = "Minha Garagem";

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          package: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha a cor de destaque',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: themeProvider.primaryColor.value == color.value
                          ? const Icon(Icons.check, color: Colors.black)
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

  void _exportarBackup() async {
    // Exemplo de chamada. Conecte com suas listas reais do banco de dados
    final abastecimentosFicticios = [
      {'id': 1, 'data': '01/10/2026', 'valor': 50.0, 'litros': 8.5, 'km': 12000}
    ];
    final manutencoesFicticias = [
      {'id': 1, 'data': '15/09/2026', 'descricao': 'Troca de Óleo', 'valor': 45.0, 'km': 11500}
    ];

    await ExportService.exportarParaCSV(
      abastecimentos: abastecimentosFicticios,
      manutencoes: manutencoesFicticias,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _nomeMoto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: 'Alterar Cor',
            onPressed: () => _abrirSeletorDeCores(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
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
          // Substitua cada Center pela sua respectiva tela criada no projeto
          Center(child: Text('Aba 1: Resumo / Gastos')),
          Center(child: Text('Aba 2: Historico Abastecimentos')),
          Center(child: Text('Aba 3: Manutenções')),
          Center(child: Text('Aba 4: Configurações')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
            icon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Abastecer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Serviços',
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