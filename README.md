# 🍔 Lanchonete Manager

Sistema completo de gestão de produção para lanchonetes, desenvolvido em Flutter.

---


##  Estrutura do Projeto

```
lib/
├── main.dart                    # Entry point + AuthGate
├── models/
│   └── models.dart             # Produto, Pedido, Ingrediente, Funcionario
├── services/
│   ├── database_service.dart   # SQLite CRUD completo
│   └── auth_service.dart       # Login, senha, recuperação por email
├── theme/
│   ├── app_theme.dart          # Temas claro/escuro com paleta premium
│   └── theme_provider.dart     # ChangeNotifier para toggle de tema
├── widgets/
│   └── common_widgets.dart     # AppLogo, StatCard, StatusBadge, etc.
└── screens/
    ├── login_screen.dart       # Login + setup + recuperação de senha
    ├── dashboard_screen.dart   # Dashboard com métricas + MainShell
    ├── pedidos_screen.dart     # Gestão de pedidos com kanban
    ├── produtos_screen.dart    # Cardápio com CRUD completo
    ├── estoque_screen.dart     # Controle de ingredientes (A-Z)
    └── funcionarios_screen.dart # Equipe com CRUD completo
```

---

## ✅ Requisitos Atendidos

| Requisito | Status | Implementação |
|-----------|--------|---------------|
| Tema claro/escuro | ✅ | `ThemeProvider` + botão toggle em todas as telas |
| Harmonização visual | ✅ | Paleta amber/gold, tipografia Playfair Display + DM Sans |
| CRUD + banco permanente | ✅ | SQLite via `sqflite` — persiste entre sessões |
| Senha de acesso | ✅ | SHA-256 hash salvo em `SharedPreferences` |
| Recuperação via e-mail | ✅ | Código de 6 dígitos enviado via `mailto:` |
| Ordenação alfabética | ✅ | Estoque e Funcionários ordenados A-Z (`ORDER BY nome ASC`) |
| Design responsivo | ✅ | `LayoutBuilder` + `GridView` adaptativo + bottom sheets |
| Capacidade de deploy | ✅ | Suporte a APK, AAB, iOS e Web |
| Mínimo 4 janelas | ✅ | Dashboard, Pedidos, Cardápio, Estoque, Equipe (5 telas) |

---

##  Telas do Aplicativo

### 1.  Login / Setup
- Primeira execução: cria senha e e-mail de recuperação
- Login com senha criptografada (SHA-256)
- Recuperação via código enviado por e-mail
- Redefinição de senha com validação de código temporário

### 2.  Dashboard
- Métricas do dia: pedidos, faturamento, pedidos pendentes, estoque baixo
- Alerta visual quando ingredientes estão abaixo do mínimo
- Lista dos pedidos recentes com status colorido
- Toggle de tema claro/escuro
- Botão de logout com confirmação

### 3.  Pedidos
- Abas por status: Todos / Pendente / Preparando / Pronto / Entregue
- Fluxo de produção: Pendente → Preparando → Pronto → Entregue
- Criar novo pedido com seleção de produtos e quantidades
- Campo de observações por pedido
- Cancelar pedido com confirmação

### 4.  Cardápio (Produtos)
- Busca em tempo real por nome ou categoria
- Filtros por categoria com chips animados
- CRUD completo com bottom sheet
- Exibe preço, estoque e descrição

### 5.  Estoque (Ingredientes)
- Lista ordenada A-Z com indicador de ordenação
- Barra de progresso visual por nível de estoque
- Alerta de estoque baixo com filtro rápido
- CRUD completo com unidades de medida variadas

### 6.  Equipe (Funcionários)
- Lista ordenada A-Z com avatar de iniciais
- Badge colorido por cargo
- Informações de contato (telefone + e-mail)
- CRUD completo

---

##  Design System

### Cores
- **Primary**: `#D4A853` (âmbar dourado)
- **Accent**: `#E8543A` (vermelho quente)
- **Success**: `#4CAF7D` | **Warning**: `#F5A623` | **Error**: `#E53935`
- Fundo claro: `#FAF7F2` | Fundo escuro: `#0F0C08`

### Tipografia
- **Display / Títulos**: Playfair Display (serifada elegante)
- **Corpo / UI**: DM Sans (sans-serif moderna e legível)

---

##  Dependências Principais

```yaml
provider: ^6.1.1          # State management
sqflite: ^2.3.0           # Banco de dados SQLite local
shared_preferences: ^2.2.2 # Persistência de configurações
crypto: ^3.0.3            # Hash SHA-256 para senhas
google_fonts: ^6.1.0      # Fontes Playfair Display e DM Sans
url_launcher: ^6.2.2      # Abrir cliente de e-mail
uuid: ^4.3.3              # IDs únicos
flutter_animate: ^4.3.0   # Animações
fl_chart: ^0.66.2         # Gráficos (expansão futura)
intl: ^0.19.0             # Formatação de datas/moedas
```
