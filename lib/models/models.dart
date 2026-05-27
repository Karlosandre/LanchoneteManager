// lib/models/models.dart

class Produto {
  final String id;
  String nome;
  String categoria;
  double preco;
  int estoque;
  String unidade;
  String? descricao;
  bool ativo;
  DateTime criadoEm;

  Produto({
    required this.id, required this.nome, required this.categoria,
    required this.preco, required this.estoque, required this.unidade,
    this.descricao, this.ativo = true, required this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'nome': nome, 'categoria': categoria, 'preco': preco,
    'estoque': estoque, 'unidade': unidade, 'descricao': descricao,
    'ativo': ativo ? 1 : 0, 'criado_em': criadoEm.toIso8601String(),
  };

  factory Produto.fromMap(Map<String, dynamic> map) => Produto(
    id: map['id'], nome: map['nome'], categoria: map['categoria'],
    preco: (map['preco'] as num).toDouble(), estoque: map['estoque'],
    unidade: map['unidade'], descricao: map['descricao'],
    ativo: map['ativo'] == 1, criadoEm: DateTime.parse(map['criado_em']),
  );
}

class Pedido {
  final String id;
  String cliente;
  List<ItemPedido> itens;
  StatusPedido status;
  DateTime criadoEm;
  DateTime? concluidoEm;
  String? observacao;
  double desconto;

  Pedido({
    required this.id, required this.cliente, required this.itens,
    required this.status, required this.criadoEm, this.concluidoEm,
    this.observacao, this.desconto = 0,
  });

  double get subtotal => itens.fold(0, (s, i) => s + i.subtotal);
  double get total => subtotal - desconto;

  Map<String, dynamic> toMap() => {
    'id': id, 'cliente': cliente, 'status': status.name,
    'criado_em': criadoEm.toIso8601String(),
    'concluido_em': concluidoEm?.toIso8601String(),
    'observacao': observacao, 'desconto': desconto,
  };

  factory Pedido.fromMap(Map<String, dynamic> map, List<ItemPedido> itens) => Pedido(
    id: map['id'], cliente: map['cliente'], itens: itens,
    status: StatusPedido.values.firstWhere((e) => e.name == map['status']),
    criadoEm: DateTime.parse(map['criado_em']),
    concluidoEm: map['concluido_em'] != null ? DateTime.parse(map['concluido_em']) : null,
    observacao: map['observacao'],
    desconto: (map['desconto'] as num?)?.toDouble() ?? 0,
  );
}

class ItemPedido {
  final String id;
  String pedidoId; // mutable - set after Pedido id is known
  final String produtoId;
  String nomeProduto;
  int quantidade;
  double precoUnitario;

  ItemPedido({
    required this.id, required this.pedidoId, required this.produtoId,
    required this.nomeProduto, required this.quantidade, required this.precoUnitario,
  });

  double get subtotal => quantidade * precoUnitario;

  Map<String, dynamic> toMap() => {
    'id': id, 'pedido_id': pedidoId, 'produto_id': produtoId,
    'nome_produto': nomeProduto, 'quantidade': quantidade,
    'preco_unitario': precoUnitario,
  };

  factory ItemPedido.fromMap(Map<String, dynamic> map) => ItemPedido(
    id: map['id'], pedidoId: map['pedido_id'], produtoId: map['produto_id'],
    nomeProduto: map['nome_produto'], quantidade: map['quantidade'],
    precoUnitario: (map['preco_unitario'] as num).toDouble(),
  );
}

enum StatusPedido {
  pendente, preparando, pronto, entregue, cancelado;

  String get label {
    switch (this) {
      case StatusPedido.pendente:   return 'Pendente';
      case StatusPedido.preparando: return 'Preparando';
      case StatusPedido.pronto:     return 'Pronto';
      case StatusPedido.entregue:   return 'Entregue';
      case StatusPedido.cancelado:  return 'Cancelado';
    }
  }
}

class Ingrediente {
  final String id;
  String nome;
  double quantidade;
  String unidade;
  double quantidadeMinima;
  double custoUnitario;
  DateTime atualizadoEm;

  Ingrediente({
    required this.id, required this.nome, required this.quantidade,
    required this.unidade, required this.quantidadeMinima,
    required this.custoUnitario, required this.atualizadoEm,
  });

  bool get estoqueBaixo => quantidade <= quantidadeMinima;

  Map<String, dynamic> toMap() => {
    'id': id, 'nome': nome, 'quantidade': quantidade, 'unidade': unidade,
    'quantidade_minima': quantidadeMinima, 'custo_unitario': custoUnitario,
    'atualizado_em': atualizadoEm.toIso8601String(),
  };

  factory Ingrediente.fromMap(Map<String, dynamic> map) => Ingrediente(
    id: map['id'], nome: map['nome'],
    quantidade: (map['quantidade'] as num).toDouble(),
    unidade: map['unidade'],
    quantidadeMinima: (map['quantidade_minima'] as num).toDouble(),
    custoUnitario: (map['custo_unitario'] as num).toDouble(),
    atualizadoEm: DateTime.parse(map['atualizado_em']),
  );
}

class Funcionario {
  final String id;
  String nome;
  String cargo;
  String telefone;
  String email;
  bool ativo;
  DateTime admissaoEm;

  Funcionario({
    required this.id, required this.nome, required this.cargo,
    required this.telefone, required this.email,
    this.ativo = true, required this.admissaoEm,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'nome': nome, 'cargo': cargo, 'telefone': telefone,
    'email': email, 'ativo': ativo ? 1 : 0,
    'admissao_em': admissaoEm.toIso8601String(),
  };

  factory Funcionario.fromMap(Map<String, dynamic> map) => Funcionario(
    id: map['id'], nome: map['nome'], cargo: map['cargo'],
    telefone: map['telefone'], email: map['email'],
    ativo: map['ativo'] == 1, admissaoEm: DateTime.parse(map['admissao_em']),
  );
}
