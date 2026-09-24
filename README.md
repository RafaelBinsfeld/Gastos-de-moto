# Minha Moto — Gastos e Manutenção

Aplicativo Flutter para gerenciamento de custos, consumo de combustível e
manutenções de uma ou mais motocicletas, com dados armazenados localmente
em SQLite (via `sqflite`) e interface adaptada tanto para mobile quanto
para desktop.

## Estrutura do projeto

```
lib
├── main.dart
├── models
│   ├── abastecimento_model.dart
│   ├── manutencao_model.dart
│   └── moto_model.dart
├── database
│   └── database_helper.dart
├── providers
│   └── moto_provider.dart          # estado global: moto selecionada
├── services
│   ├── calculos_service.dart
│   ├── preferencias_service.dart
│   ├── exportacao_service.dart
│   ├── importacao_service.dart
│   └── notificacoes_service.dart
├── utils
│   └── filtro_periodo.dart
├── widgets
│   ├── main_shell.dart             # navegação responsiva (rail/bottom nav)
│   ├── moto_switcher.dart          # ação de trocar de moto na AppBar
│   └── responsive_helpers.dart
└── screens
    ├── home_screen.dart
    ├── historico_screen.dart       # listas completas com filtros
    ├── abastecimento_form_screen.dart
    ├── manutencao_form_screen.dart
    ├── relatorios_screen.dart
    ├── configuracoes_screen.dart
    └── motos_screen.dart           # gerenciar motocicletas
```

Essa estrutura segue a arquitetura em camadas do documento de
especificação original (models, database, services, screens), estendida
com `providers`, `utils` e `widgets` para suportar múltiplas motos e um
layout responsivo.

## Como rodar

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Extraia este pacote. Como aqui só é fornecido o código-fonte (`lib/` e
   `pubspec.yaml`), gere os projetos de cada plataforma dentro da pasta:
   ```bash
   cd moto_gastos_app
   flutter create .
   ```
   Isso cria as pastas `android/`, `ios/`, `windows/`, `macos/`, `linux/`
   e `web/` sem sobrescrever o código já existente em `lib/`.
3. Baixe as dependências:
   ```bash
   flutter pub get
   ```
4. **Se for gerar um APK para Android**, siga a seção "Configuração
   obrigatória do Android" abaixo antes do próximo passo — sem ela o
   `flutter build apk` falha.
5. Execute em um emulador/dispositivo móvel ou como app desktop:
   ```bash
   flutter run                # escolhe o dispositivo disponível
   flutter run -d windows     # ou -d macos / -d linux / -d chrome
   flutter build apk          # gera o APK para instalar no celular
   ```

### Configuração obrigatória do Android

Os plugins nativos usados neste app (`flutter_local_notifications` para os
alertas de troca de óleo, `file_picker` para importar CSV e o avatar da
moto) exigem ajustes no `android/app/build.gradle.kts` que o `flutter
create .` não faz sozinho. Faça isso **uma única vez**, logo depois do
`flutter create .`:

1. Abra `android/app/build.gradle.kts` e substitua todo o conteúdo por:

   ```kotlin
   import org.jetbrains.kotlin.gradle.dsl.JvmTarget

   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
   }

   android {
       namespace = "com.example.moto_gastos_app"
       compileSdk = 36
       ndkVersion = flutter.ndkVersion

       compileOptions {
           isCoreLibraryDesugaringEnabled = true
           sourceCompatibility = JavaVersion.VERSION_17
           targetCompatibility = JavaVersion.VERSION_17
       }

       defaultConfig {
           applicationId = "com.example.moto_gastos_app"
           minSdk = 23
           targetSdk = flutter.targetSdkVersion
           versionCode = flutter.versionCode
           versionName = flutter.versionName
           multiDexEnabled = true
       }

       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("debug")
           }
       }
   }

   kotlin {
       compilerOptions {
           jvmTarget.set(JvmTarget.JVM_17)
       }
   }

   flutter {
       source = "../.."
   }

   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```

   > Se o seu `namespace`/`applicationId` original já era diferente de
   > `com.example.moto_gastos_app` (por exemplo, se você mudou ao rodar
   > `flutter create`), troque só essas duas linhas pelo valor que já
   > estava lá.

2. Garanta que o **Android SDK Platform 36** está instalado (senão o
   Gradle falha com algo como "Failed to find Platform SDK"):
   ```bash
   flutter doctor --android-licenses
   sdkmanager "platforms;android-36"
   ```
   ou instale pelo Android Studio → SDK Manager → marque "Android 16 (API
   36)".

3. Em `android/app/src/main/AndroidManifest.xml`, garanta a permissão de
   internet dentro da tag `<manifest>` (fora da `<application>`) — sem
   ela, as fontes do app (Big Shoulders Display / Manrope, carregadas via
   `google_fonts`) não conseguem ser baixadas num build de release, e o
   app cai silenciosamente para a fonte padrão do sistema:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

4. Depois dos três passos acima:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

Um aviso amarelo sobre `share_plus` e o Kotlin Gradle Plugin (KGP) pode
aparecer no log — é só um alerta sobre versões futuras do Flutter, não
impede o build.

### Outras notas de plataforma

- **Banco de dados no desktop** (`sqflite_common_ffi`): o `sqflite` só tem
  implementação nativa para Android e iOS. Em Windows, Linux e macOS o
  app usa automaticamente a implementação via FFI (já configurada em
  `main.dart`). Em modo debug no Windows o `sqlite3.dll` já vem embutido;
  se um build de **release** para Windows não encontrar o banco, copie o
  `sqlite3.dll` mais recente para a pasta do executável (veja a seção
  "Windows" da documentação do
  [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)).
- **Notificações locais** (`flutter_local_notifications`): no Android 13+
  é necessária a permissão de notificações, já solicitada em tempo de
  execução pelo app; no iOS, a permissão é solicitada via `Info.plist`
  padrão gerado pelo `flutter create`.
- **Seleção de arquivos** (`file_picker`, usado na importação de CSV e no
  avatar da moto): funciona out-of-the-box no Android, iOS, Windows,
  macOS e Linux. No macOS pode ser necessário habilitar o entitlement de
  acesso a arquivos do usuário caso o sandbox esteja ativado.
- **Compartilhamento** (`share_plus`, usado na exportação de CSV): também
  não exige configuração extra nas plataformas suportadas.

## Funcionalidades implementadas

- **CRUD completo de abastecimentos e manutenções** persistidos em
  SQLite, com edição e exclusão diretamente nas listas (deslizar para
  excluir, tocar para editar) tanto na Home quanto no Histórico.
- **Suporte a múltiplas motocicletas**: cada moto tem seu próprio
  histórico, intervalo de troca de óleo e métricas. Um seletor de moto
  fica disponível na AppBar de todas as telas principais, e a tela
  "Minhas Motocicletas" permite adicionar, editar e excluir motos.
- **Filtros por período e tipo de serviço**: a tela de Histórico traz
  abas de Abastecimentos/Manutenções com filtro por período (este mês,
  últimos 3/6 meses, este ano, todos) e, para manutenções, filtro por
  tipo de serviço. Os Relatórios também respeitam o filtro de período
  selecionado.
- **Gráficos de evolução** (`fl_chart`) nos Relatórios: linha de evolução
  do consumo (km/l) e barras de gastos mensais (combustível vs.
  manutenção) dos últimos 6 meses.
- **Intervalo de troca de óleo configurável por moto**, editado na tela
  "Minhas Motocicletas" (ou pelo atalho em Configurações).
- **Notificações locais** quando a troca de óleo está próxima ou vencida,
  com opção de ativar/desativar em Configurações.
- **Exportação e importação de CSV**: no menu da tela de Relatórios é
  possível exportar (e compartilhar) ou importar abastecimentos e
  manutenções, permitindo fazer e restaurar backups.
- **Interface responsiva**: em telas largas (>= 900px) o app usa uma
  `NavigationRail` lateral (estendida com rótulos a partir de 1200px) e
  abre formulários como diálogos centralizados; em telas estreitas usa
  navegação inferior e telas cheias, como um app mobile tradicional.
- **Serviço de regras de negócio** (`calculos_service.dart`) com as
  fórmulas de consumo (km/l), custo por km, custo total de manutenção e
  alerta de troca de óleo (em dia / próxima / vencida).

## Pacotes utilizados

- `sqflite` / `path` — persistência local em SQLite.
- `intl` — formatação de datas e valores monetários (pt_BR).
- `provider` — estado global da moto selecionada.
- `fl_chart` — gráficos de evolução de consumo e gastos.
- `google_fonts` — tipografia customizada (Big Shoulders Display + Manrope).
- `shared_preferences` — preferências do app (moto selecionada,
  notificações ativadas).
- `csv` — geração e leitura dos arquivos de exportação/importação.
- `share_plus` — folha de compartilhamento nativa ao exportar CSV.
- `file_picker` — seleção de arquivo CSV ao importar e da foto/avatar da moto.
- `path_provider` — diretório temporário para salvar o CSV antes de
  compartilhar.
- `flutter_local_notifications` — notificações locais de troca de óleo.

## Identidade visual

O app foge do visual genérico de Material Design "de fábrica": a paleta e a
tipografia são pensadas para lembrar o painel e a oficina de uma moto, não
um dashboard de SaaS.

- **Paleta** (`lib/theme/app_theme.dart`, classe `CoresApp`): âmbar de
  marcador de combustível (`ambarPainel`), aço/asfalto profundo
  (`acoAsfalto`), grafite (`grafite`), neblina (`neblina`), ferrugem para
  alertas (`ferrugem`) e verde musgo para "em dia" (`verdeMusgo`) — em vez
  do azul/roxo genérico de `ColorScheme.fromSeed`.
- **Tipografia**: títulos e números grandes em **Big Shoulders Display**
  (condensada, de inspiração industrial/rodoviária), texto em **Manrope**
  — via `google_fonts`, carregadas dinamicamente (não é preciso empacotar
  fontes).
- **Painel de instrumentos** (`lib/widgets/painel_instrumentos.dart`): o
  card de resumo da Home foi substituído por um painel sempre escuro (como
  o mostrador retroiluminado de uma moto de verdade), com um medidor em
  arco desenhado à mão (`CustomPainter`) mostrando o quanto falta para a
  próxima troca de óleo.
- **Listas** (`lib/widgets/linha_registro.dart`): linhas de abastecimento e
  manutenção com uma barra de destaque colorida lateral em vez do ícone
  circular genérico do `ListTile` padrão.
- **Tema claro/escuro/sistema**: alternável em Configurações
  (`ThemeProvider`, persistido com `shared_preferences`).

## Avatar da motocicleta

Em "Minhas Motocicletas", ao criar ou editar uma moto é possível tocar no
ícone de câmera sobre o avatar para importar uma foto (`file_picker`,
filtrando por imagem). O arquivo escolhido é copiado para a pasta de
documentos do app (`moto_images/`), então a imagem continua disponível
mesmo que o arquivo original (da galeria, por exemplo) seja movido ou
apagado depois. O avatar aparece no seletor de moto da AppBar, na lista de
motos e no painel de instrumentos da Home.

## Migração de dados

Instalações que já existiam antes do suporte a múltiplas motos (schema
v1) ou antes do avatar de moto (schema v2) são migradas automaticamente
na primeira abertura após a atualização: uma moto padrão "Minha Moto" é
criada (se necessário) e a coluna de imagem é adicionada — nenhum dado é
perdido.

## Próximos passos sugeridos

- Reordenar/arquivar motocicletas antigas.
- Notificações agendadas (não só ao abrir o app) usando `flutter_local_notifications` com `timezone`.
- Gráfico comparativo de consumo entre motos.
- Testes automatizados para o `calculos_service.dart` e o `database_helper.dart`.
