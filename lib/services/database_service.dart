// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._internal();
  factory DatabaseService() => _instance ??= DatabaseService._internal();

  Future<Database> get db async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'lanchonete.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produtos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        preco REAL NOT NULL,
        estoque INTEGER NOT NULL,
        unidade TEXT NOT NULL,
        descricao TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos (
        id TEXT PRIMARY KEY,
        cliente TEXT NOT NULL,
        status TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        concluido_em TEXT,
        observacao TEXT,
        desconto REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE itens_pedido (
        id TEXT PRIMARY KEY,
        pedido_id TEXT NOT NULL,
        produto_id TEXT NOT NULL,
        nome_produto TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        preco_unitario REAL NOT NULL,
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredientes (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade TEXT NOT NULL,
        quantidade_minima REAL NOT NULL,
        custo_unitario REAL NOT NULL,
        atualizado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE funcionarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        cargo TEXT NOT NULL,
        telefone TEXT NOT NULL,
        email TEXT NOT NULL,
        ativo INTEGER NOT NULL DEFAULT 1,
        admissao_em TEXT NOT NULL
      )
    ''');

    await _insertSeedData(db);
  }

  Future<void> _insertSeedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    await db.insert('produtos', {
      'id': 'p1', 'nome': 'X-Burguer', 'categoria': 'Lanches',
      'preco': 18.90, 'estoque': 50, 'unidade': 'un', 'ativo': 1, 'criado_em': now,
      'descricao': 'Pão, hambúrguer, queijo, alface e tomate',
    });
    await db.insert('produtos', {
      'id': 'p2', 'nome': 'X-Bacon', 'categoria': 'Lanches',
      'preco': 22.50, 'estoque': 40, 'unidade': 'un', 'ativo': 1, 'criado_em': now,
      'descricao': 'Pão, hambúrguer duplo, bacon, queijo e maionese',
    });
    await db.insert('produtos', {
      'id': 'p3', 'nome': 'Coca-Cola 350ml', 'categoria': 'Bebidas',
      'preco': 6.00, 'estoque': 100, 'unidade': 'un', 'ativo': 1, 'criado_em': now,
    });
    await db.insert('produtos', {
      'id': 'p4', 'nome': 'Fritas Grandes', 'categoria': 'Acompanhamentos',
      'preco': 12.00, 'estoque': 60, 'unidade': 'un', 'ativo': 1, 'criado_em': now,
      'descricao': 'Batata frita crocante tamanho grande',
    });
    await db.insert('produtos', {
      'id': 'p5', 'nome': 'Milk-Shake', 'categoria': 'Bebidas',
      'preco': 16.00, 'estoque': 30, 'unidade': 'un', 'ativo': 1, 'criado_em': now,
      'descricao': 'Sorvete cremoso sabores variados',
    });

    await db.insert('ingredientes', {
      'id': 'i1', 'nome': 'Carne Bovina (kg)', 'quantidade': 5.0,
      'unidade': 'kg', 'quantidade_minima': 2.0, 'custo_unitario': 38.00, 'atualizado_em': now,
    });
    await db.insert('ingredientes', {
      'id': 'i2', 'nome': 'Bacon (kg)', 'quantidade': 1.2,
      'unidade': 'kg', 'quantidade_minima': 1.5, 'custo_unitario': 42.00, 'atualizado_em': now,
    });
    await db.insert('ingredientes', {
      'id': 'i3', 'nome': 'Pão de Hambúrguer', 'quantidade': 80,
      'unidade': 'un', 'quantidade_minima': 20, 'custo_unitario': 1.20, 'atualizado_em': now,
    });
    await db.insert('ingredientes', {
      'id': 'i4', 'nome': 'Queijo Fatiado (kg)', 'quantidade': 2.5,
      'unidade': 'kg', 'quantidade_minima': 1.0, 'custo_unitario': 35.00, 'atualizado_em': now,
    });
    await db.insert('ingredientes', {
      'id': 'i5', 'nome': 'Batata Pré-Frita (kg)', 'quantidade': 8.0,
      'unidade': 'kg', 'quantidade_minima': 3.0, 'custo_unitario': 12.00, 'atualizado_em': now,
    });

    await db.insert('funcionarios', {
      'id': 'f1', 'nome': 'Ana Paula Silva', 'cargo': 'Gerente',
      'telefone': '(71) 99999-0001', 'email': 'ana@lanchonete.com',
      'ativo': 1, 'admissao_em': now,
    });
    await db.insert('funcionarios', {
      'id': 'f2', 'nome': 'Bruno Santos', 'cargo': 'Cozinheiro',
      'telefone': '(71) 99999-0002', 'email': 'bruno@lanchonete.com',
      'ativo': 1, 'admissao_em': now,
    });
    await db.insert('funcionarios', {
      'id': 'f3', 'nome': 'Carlos Mendes', 'cargo': 'Atendente',
      'telefone': '(71) 99999-0003', 'email': 'carlos@lanchonete.com',
      'ativo': 1, 'admissao_em': now,
    });
  }

  // === PRODUTOS ===
  Future<List<Produto>> getProdutos() async {
    final d = await db;
    final maps = await d.query('produtos', orderBy: 'nome ASC');
    return maps.map((m) => Produto.fromMap(m)).toList();
  }

  Future<Produto?> getProduto(String id) async {
    final d = await db;
    final maps = await d.query('produtos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Produto.fromMap(maps.first);
  }

  Future<void> insertProduto(Produto p) async {
    final d = await db;
    await d.insert('produtos', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduto(Produto p) async {
    final d = await db;
    await d.update('produtos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteProduto(String id) async {
    final d = await db;
    await d.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  // === PEDIDOS ===
  Future<List<Pedido>> getPedidos() async {
    final d = await db;
    final maps = await d.query('pedidos', orderBy: 'criado_em DESC');
    final pedidos = <Pedido>[];
    for (final m in maps) {
      final itens = await getItensPedido(m['id'] as String);
      pedidos.add(Pedido.fromMap(m, itens));
    }
    return pedidos;
  }

  Future<List<ItemPedido>> getItensPedido(String pedidoId) async {
    final d = await db;
    final maps = await d.query('itens_pedido', where: 'pedido_id = ?', whereArgs: [pedidoId]);
    return maps.map((m) => ItemPedido.fromMap(m)).toList();
  }

  Future<void> insertPedido(Pedido pedido) async {
    final d = await db;
    await d.insert('pedidos', pedido.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in pedido.itens) {
      await d.insert('itens_pedido', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updatePedidoStatus(String id, StatusPedido status) async {
    final d = await db;
    final updates = {'status': status.name};
    if (status == StatusPedido.entregue || status == StatusPedido.cancelado) {
      updates['concluido_em'] = DateTime.now().toIso8601String();
    }
    await d.update('pedidos', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePedido(String id) async {
    final d = await db;
    await d.delete('itens_pedido', where: 'pedido_id = ?', whereArgs: [id]);
    await d.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  }

  // === INGREDIENTES ===
  Future<List<Ingrediente>> getIngredientes() async {
    final d = await db;
    final maps = await d.query('ingredientes', orderBy: 'nome ASC');
    return maps.map((m) => Ingrediente.fromMap(m)).toList();
  }

  Future<void> insertIngrediente(Ingrediente i) async {
    final d = await db;
    await d.insert('ingredientes', i.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateIngrediente(Ingrediente i) async {
    final d = await db;
    await d.update('ingredientes', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
  }

  Future<void> deleteIngrediente(String id) async {
    final d = await db;
    await d.delete('ingredientes', where: 'id = ?', whereArgs: [id]);
  }

  // === FUNCIONARIOS ===
  Future<List<Funcionario>> getFuncionarios() async {
    final d = await db;
    final maps = await d.query('funcionarios', orderBy: 'nome ASC');
    return maps.map((m) => Funcionario.fromMap(m)).toList();
  }

  Future<void> insertFuncionario(Funcionario f) async {
    final d = await db;
    await d.insert('funcionarios', f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFuncionario(Funcionario f) async {
    final d = await db;
    await d.update('funcionarios', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
  }

  Future<void> deleteFuncionario(String id) async {
    final d = await db;
    await d.delete('funcionarios', where: 'id = ?', whereArgs: [id]);
  }

  // === STATS ===
  Future<Map<String, dynamic>> getDashboardStats() async {
    final d = await db;
    final pedidosHoje = await d.rawQuery('''
      SELECT COUNT(*) as count, SUM(
        (SELECT SUM(quantidade * preco_unitario) FROM itens_pedido WHERE pedido_id = pedidos.id)
      ) as total
      FROM pedidos 
      WHERE date(criado_em) = date('now') AND status != 'cancelado'
    ''');
    final totalProdutos = await d.rawQuery('SELECT COUNT(*) as count FROM produtos WHERE ativo = 1');
    final estoqueBaixo = await d.rawQuery(
      'SELECT COUNT(*) as count FROM ingredientes WHERE quantidade <= quantidade_minima'
    );
    final pedidosPendentes = await d.rawQuery(
      "SELECT COUNT(*) as count FROM pedidos WHERE status IN ('pendente','preparando')"
    );
    return {
      'pedidosHoje': pedidosHoje.first['count'] ?? 0,
      'vendasHoje': pedidosHoje.first['total'] ?? 0.0,
      'totalProdutos': totalProdutos.first['count'] ?? 0,
      'estoqueBaixo': estoqueBaixo.first['count'] ?? 0,
      'pedidosPendentes': pedidosPendentes.first['count'] ?? 0,
    };
  }
}
