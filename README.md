# 🍽️ Sistema de Restaurante & Bar — Documentação do Banco de Dados

> **Banco:** `restaurante_bar` · **SGBD:** MySQL 8.0+ · **Charset:** utf8mb4 · **Versão:** 1.0

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Diagrama MER (Entidade-Relacionamento)](#diagrama-mer)
3. [Módulos do Sistema](#módulos-do-sistema)
4. [Dicionário de Tabelas](#dicionário-de-tabelas)
5. [Relacionamentos Detalhados](#relacionamentos-detalhados)
6. [Regras de Negócio (Triggers)](#regras-de-negócio-triggers)
7. [Stored Procedures](#stored-procedures)
8. [Views](#views)
9. [Índices](#índices)
10. [Como Executar](#como-executar)

---

## Visão Geral

Este modelo cobre todo o ciclo operacional de um restaurante e bar com múltiplas filiais, incluindo:

- Gestão de mesas, reservas e áreas físicas
- Cardápio com produtos, combos e categorias
- Pedidos para mesa, balcão e delivery
- Controle de estoque via ficha técnica
- Pagamentos multi-forma e emissão de nota fiscal
- Programa de fidelidade e coupons de desconto
- Funcionários, cargos e turnos de trabalho
- Eventos e avaliações de clientes

---

## Diagrama MER

O diagrama abaixo representa os relacionamentos em notação **Crow's Foot** (pé-de-galinha):

```
┌─────────────┐        ┌──────────────┐        ┌────────────┐
│   endereco  │◄───────│    filial    │───────►│    area    │
└─────────────┘  1:N   └──────────────┘  1:N   └────────────┘
      ▲                       │                      │ 1:N
      │ (opt)                 │ 1:N                  ▼
      │               ┌───────────────┐        ┌────────────┐
┌─────────────┐        │  funcionario  │        │    mesa    │
│   cliente   │        └───────────────┘        └────────────┘
└─────────────┘               │ 1:N                  ▲
      │ (opt)                 │              (opt)   │
      │ 1:N           ┌───────────────┐        ┌────────────┐
      │               │     turno     │        │   reserva  │
      │               └───────────────┘        └────────────┘
      │                                               │
      │ 1:N           ┌───────────────┐              │
      └──────────────►│    pedido     │◄─────────────┘
                       └───────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
       ┌────────────┐  ┌────────────┐  ┌────────────────┐
       │item_pedido │  │ pagamento  │  │pedido_delivery │
       └────────────┘  └────────────┘  └────────────────┘
              │               │
     ┌────────┴────┐          │
     ▼             ▼          ▼
 ┌─────────┐  ┌─────────┐ ┌─────────────────┐
 │ produto │  │  combo  │ │ forma_pagamento  │
 └─────────┘  └─────────┘ └─────────────────┘
      │
      ├──────────────────────┐
      ▼                      ▼
┌──────────────┐      ┌─────────────┐
│ficha_tecnica │      │ combo_item  │
└──────────────┘      └─────────────┘
      │
      ▼
┌──────────────┐      ┌───────────────────┐
│    insumo    │◄─────│movimento_estoque  │
└──────────────┘      └───────────────────┘
      │
      ▼
┌──────────────┐
│  fornecedor  │
└──────────────┘
```

### Cardinalidades Principais

| Relacionamento | Tipo | Descrição |
|---|---|---|
| `filial` → `area` | 1:N | Uma filial possui várias áreas (salão, bar, terraço) |
| `area` → `mesa` | 1:N | Uma área contém várias mesas |
| `filial` → `funcionario` | 1:N | Funcionários pertencem a uma filial |
| `cargo` → `funcionario` | 1:N | Vários funcionários podem ter o mesmo cargo |
| `pedido` → `item_pedido` | 1:N | Um pedido tem um ou mais itens |
| `produto` → `item_pedido` | 1:N | Um produto pode estar em muitos itens |
| `combo` ↔ `produto` | N:M | via `combo_item` — um combo agrupa vários produtos |
| `produto` ↔ `insumo` | N:M | via `ficha_tecnica` — um produto consome vários insumos |
| `pedido` → `pagamento` | 1:N | Um pedido pode ser pago em partes (ex: divisão de conta) |
| `pedido` ↔ `coupon` | N:M | via `pedido_coupon` — um pedido pode usar múltiplos coupons |
| `cliente` → `fidelidade_transacao` | 1:N | Histórico de pontos do cliente |

---

## Módulos do Sistema

```
restaurante_bar/
├── 🏢 Estrutura Física     → endereco, filial, area, mesa
├── 👤 Pessoal              → cargo, funcionario, turno
├── 🙋 Clientes             → cliente, avaliacao
├── 🗓️ Reservas             → reserva
├── 🍕 Cardápio             → categoria_produto, produto, combo, combo_item
├── 📦 Estoque              → insumo, ficha_tecnica, movimento_estoque, fornecedor
├── 🧾 Pedidos              → pedido, item_pedido
├── 💳 Financeiro           → pagamento, forma_pagamento, nota_fiscal, caixa
├── 🎁 Promoções            → coupon, pedido_coupon, fidelidade_transacao
├── 🛵 Delivery             → entregador, pedido_delivery
└── 🎉 Eventos              → evento
```

---

## Dicionário de Tabelas

### 🏢 Módulo: Estrutura Física

---

#### `endereco`
Tabela de endereços reutilizável. Compartilhada por `filial`, `cliente`, `fornecedor` e `pedido_delivery`.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `logradouro` | VARCHAR(150) | ✅ | Rua, Avenida, etc. |
| `numero` | VARCHAR(10) | ✅ | Número do imóvel |
| `complemento` | VARCHAR(60) | ❌ | Apto, Bloco, etc. |
| `bairro` | VARCHAR(80) | ✅ | Bairro |
| `cidade` | VARCHAR(80) | ✅ | Cidade |
| `estado` | CHAR(2) | ✅ | UF (ex: SP) |
| `cep` | CHAR(9) | ✅ | Formato `00000-000` |

> **Constraint:** CEP deve seguir o padrão `00000-000`.

---

#### `filial`
Representa cada unidade física do negócio (pode ser uma rede com múltiplas filiais).

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `nome` | VARCHAR(100) | ✅ | Nome da filial |
| `cnpj` | CHAR(18) | ✅ UNIQUE | CNPJ no formato `00.000.000/0000-00` |
| `telefone` | VARCHAR(20) | ❌ | Telefone de contato |
| `email` | VARCHAR(120) | ❌ | E-mail institucional |
| `endereco_id` | INT UNSIGNED | ✅ FK | Referência ao endereço |
| `ativa` | TINYINT(1) | ✅ | `1` = ativa, `0` = inativa |

---

#### `area`
Setores físicos dentro de uma filial (Salão Principal, Bar, Terraço, VIP, Delivery).

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `filial_id` | INT UNSIGNED | ✅ FK | Filial à qual a área pertence |
| `nome` | VARCHAR(60) | ✅ | Nome do setor |
| `descricao` | VARCHAR(200) | ❌ | Descrição livre |
| `ativa` | TINYINT(1) | ✅ | `1` = ativa |

---

#### `mesa`
Representa cada mesa física de uma área. O status é gerenciado automaticamente por triggers.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `area_id` | INT UNSIGNED | ✅ FK | Área onde a mesa está |
| `numero` | SMALLINT UNSIGNED | ✅ | Número da mesa (único por área) |
| `capacidade` | TINYINT UNSIGNED | ✅ | Máximo de pessoas (1–50) |
| `status` | ENUM | ✅ | `livre` / `ocupada` / `reservada` / `manutencao` |

> **Constraint:** O número da mesa é único dentro de cada área (`UNIQUE area_id, numero`).
> **Trigger:** Status atualizado automaticamente ao abrir/fechar pedido.

---

### 👤 Módulo: Pessoal

---

#### `cargo`
Cargos disponíveis no estabelecimento com salário base de referência.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `nome` | VARCHAR(60) | ✅ UNIQUE | Nome do cargo (ex: Garçom, Barman) |
| `descricao` | VARCHAR(200) | ❌ | Descrição das responsabilidades |
| `salario_base` | DECIMAL(10,2) | ✅ | Salário base de referência |

---

#### `funcionario`
Todos os colaboradores do estabelecimento, vinculados a uma filial e a um cargo.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `filial_id` | INT UNSIGNED | ✅ FK | Filial de trabalho |
| `cargo_id` | INT UNSIGNED | ✅ FK | Cargo do funcionário |
| `nome` | VARCHAR(100) | ✅ | Nome completo |
| `cpf` | CHAR(14) | ✅ UNIQUE | CPF no formato `000.000.000-00` |
| `data_nascimento` | DATE | ✅ | Data de nascimento |
| `data_admissao` | DATE | ✅ | Data de contratação |
| `data_demissao` | DATE | ❌ | Preenchida apenas ao desligar |
| `login` | VARCHAR(60) | ❌ UNIQUE | Login para acesso ao sistema |
| `senha_hash` | VARCHAR(255) | ❌ | Hash bcrypt da senha |
| `ativo` | TINYINT(1) | ✅ | `1` = ativo |

> **Constraint:** `data_demissao` deve ser maior ou igual a `data_admissao`.

---

#### `turno`
Registro de entrada e saída de funcionários por dia de trabalho.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `funcionario_id` | INT UNSIGNED | ✅ FK | Funcionário |
| `filial_id` | INT UNSIGNED | ✅ FK | Filial do turno |
| `entrada` | DATETIME | ✅ | Horário de entrada |
| `saida` | DATETIME | ❌ | Horário de saída (nulo enquanto no turno) |

---

### 🙋 Módulo: Clientes

---

#### `cliente`
Cadastro de clientes, usado em pedidos, reservas, fidelidade e delivery.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `nome` | VARCHAR(100) | ✅ | Nome completo |
| `cpf` | CHAR(14) | ❌ UNIQUE | CPF (opcional para cadastro) |
| `data_nascimento` | DATE | ❌ | Para ações de aniversário |
| `telefone` | VARCHAR(20) | ❌ | Contato |
| `email` | VARCHAR(120) | ❌ UNIQUE | E-mail |
| `endereco_id` | INT UNSIGNED | ❌ FK | Endereço principal (delivery) |
| `pontos_fidelidade` | INT UNSIGNED | ✅ | Saldo atual de pontos |

---

#### `avaliacao`
Feedback do cliente sobre comida, atendimento e ambiente, vinculado a um pedido.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `pedido_id` | FK | Pedido avaliado |
| `nota_comida` | TINYINT (1–5) | Nota para a comida |
| `nota_atendimento` | TINYINT (1–5) | Nota para o atendimento |
| `nota_ambiente` | TINYINT (1–5) | Nota para o ambiente |
| `comentario` | TEXT | Comentário livre |

---

### 🗓️ Módulo: Reservas

---

#### `reserva`
Pré-reserva de mesa para data/hora futura, podendo ser vinculada ou não a um cliente cadastrado.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `filial_id` | INT UNSIGNED | ✅ FK | Filial da reserva |
| `cliente_id` | INT UNSIGNED | ❌ FK | Cliente cadastrado (opcional) |
| `mesa_id` | INT UNSIGNED | ❌ FK | Mesa pré-alocada (opcional) |
| `funcionario_id` | INT UNSIGNED | ✅ FK | Funcionário que cadastrou |
| `nome_contato` | VARCHAR(100) | ✅ | Nome para confirmação |
| `telefone_contato` | VARCHAR(20) | ✅ | Telefone para confirmação |
| `data_reserva` | DATETIME | ✅ | Data e hora da reserva |
| `num_pessoas` | TINYINT UNSIGNED | ✅ | Quantidade de pessoas |
| `status` | ENUM | ✅ | `pendente` / `confirmada` / `cancelada` / `concluida` |

---

### 🍕 Módulo: Cardápio

---

#### `categoria_produto`
Organiza os produtos do cardápio em grupos (Entradas, Pratos, Bebidas Alcoólicas, etc.).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `nome` | VARCHAR(80) UNIQUE | Nome da categoria |
| `tipo` | ENUM | `comida` / `bebida` / `sobremesa` / `outro` |

---

#### `produto`
Item vendável do cardápio. Cada produto pertence a uma categoria e pode ter flags de canal de venda.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `categoria_id` | INT UNSIGNED | ✅ FK | Categoria do produto |
| `codigo` | VARCHAR(30) | ✅ UNIQUE | Código interno (PDV/cardápio) |
| `nome` | VARCHAR(120) | ✅ | Nome do produto |
| `preco_venda` | DECIMAL(10,2) | ✅ | Preço ao consumidor |
| `custo_estimado` | DECIMAL(10,2) | ✅ | Custo de produção estimado |
| `tempo_preparo_min` | SMALLINT | ✅ | Tempo médio de preparo em minutos |
| `disponivel` | TINYINT(1) | ✅ | Se está ativo no cardápio |
| `vendido_no_bar` | TINYINT(1) | ✅ | Habilitado para venda no bar |
| `vendido_no_salao` | TINYINT(1) | ✅ | Habilitado para venda no salão |
| `vendido_delivery` | TINYINT(1) | ✅ | Habilitado para delivery |

---

#### `combo` + `combo_item`
Agrupa produtos em combinações com preço especial. `combo_item` é a tabela de junção N:M.

```
combo (1) ──────── N combo_item N ──────── 1 produto
```

| Tabela | Colunas relevantes |
|--------|--------------------|
| `combo` | `nome`, `preco`, `ativo` |
| `combo_item` | `combo_id` (FK), `produto_id` (FK), `quantidade` |

---

### 📦 Módulo: Estoque

---

#### `fornecedor`
Empresas que fornecem insumos ao restaurante.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `cnpj` | CHAR(18) UNIQUE | CNPJ do fornecedor |
| `razao_social` | VARCHAR(150) | Razão social |
| `nome_fantasia` | VARCHAR(150) | Nome fantasia |

---

#### `insumo`
Ingredientes e materiais de estoque. Cada insumo tem quantidade atual e nível mínimo para alerta.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `nome` | VARCHAR(120) | Nome do ingrediente |
| `unidade_medida` | VARCHAR(20) | `kg`, `L`, `un`, `cx`, etc. |
| `estoque_atual` | DECIMAL(12,3) | Quantidade atual em estoque |
| `estoque_minimo` | DECIMAL(12,3) | Quantidade mínima antes do reabastecimento |
| `custo_unitario` | DECIMAL(10,4) | Custo por unidade de medida |

---

#### `ficha_tecnica`
Tabela N:M que define quais insumos e em que quantidade são necessários para produzir cada produto.

```
produto (1) ── N ficha_tecnica N ── 1 insumo
```

> Usada pelo trigger `trg_baixa_estoque` para debitar automaticamente o estoque quando um item é entregue.

---

#### `movimento_estoque`
Log auditável de todas as entradas, saídas, ajustes e perdas de insumos.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `tipo` | ENUM | `entrada` / `saida` / `ajuste` / `perda` |
| `quantidade` | DECIMAL(12,3) | Quantidade movimentada |
| `observacao` | VARCHAR(255) | Motivo ou referência (ex: Pedido #42) |

---

### 🧾 Módulo: Pedidos

---

#### `pedido`
Comanda central do sistema. Conecta mesa, cliente, funcionário, pagamento e itens.

| Coluna | Tipo | Obrigatório | Descrição |
|--------|------|-------------|-----------|
| `id` | INT UNSIGNED | PK | Identificador único |
| `filial_id` | INT UNSIGNED | ✅ FK | Filial do pedido |
| `mesa_id` | INT UNSIGNED | ❌ FK | Nulo para delivery/balcão |
| `cliente_id` | INT UNSIGNED | ❌ FK | Cliente (opcional) |
| `funcionario_id` | INT UNSIGNED | ✅ FK | Garçom/atendente responsável |
| `tipo` | ENUM | ✅ | `mesa` / `balcao` / `delivery` |
| `status` | ENUM | ✅ | `aberto` → `em_preparo` → `pronto` → `entregue` → `fechado` |
| `subtotal` | DECIMAL(10,2) | ✅ | Soma dos itens (calculado por trigger) |
| `desconto` | DECIMAL(10,2) | ✅ | Desconto aplicado |
| `taxa_servico` | DECIMAL(10,2) | ✅ | Taxa de serviço (10% opcional) |
| `total` | DECIMAL(10,2) | COMPUTED | `subtotal - desconto + taxa_servico` |

> **Ciclo de vida do pedido:**
> ```
> aberto → em_preparo → pronto → entregue → fechado
>                                         ↘ cancelado
> ```

---

#### `item_pedido`
Cada linha da comanda. Pode referenciar um `produto` **ou** um `combo` (nunca os dois).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `produto_id` | FK (nullable) | Produto avulso |
| `combo_id` | FK (nullable) | Combo escolhido |
| `quantidade` | SMALLINT | Quantidade pedida |
| `preco_unitario` | DECIMAL | Preço no momento do pedido (snapshot) |
| `subtotal` | DECIMAL COMPUTED | `quantidade × preco_unitario - desconto` |
| `status` | ENUM | `pendente` / `em_preparo` / `pronto` / `entregue` / `cancelado` |

> **Constraint:** `produto_id` e `combo_id` são mutuamente exclusivos — um deve ser nulo e o outro não.

---

### 💳 Módulo: Financeiro

---

#### `forma_pagamento`
Cadastro dos meios de pagamento aceitos (Dinheiro, Crédito, Débito, Pix, VR, Cortesia).

---

#### `pagamento`
Registra cada transação de pagamento. Um pedido pode ter múltiplos pagamentos (divisão de conta).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `pedido_id` | FK | Pedido pago |
| `forma_pagamento_id` | FK | Forma usada |
| `valor` | DECIMAL(10,2) | Valor pago |
| `troco` | DECIMAL(10,2) | Troco (dinheiro) |
| `nsu` | VARCHAR(30) | Número de série para cartão |
| `status` | ENUM | `pendente` / `aprovado` / `recusado` / `estornado` |

---

#### `nota_fiscal`
Armazena os dados fiscais de cada pedido fechado (NF-e simplificada).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `pedido_id` | FK UNIQUE | Um pedido → uma nota |
| `numero` | VARCHAR(20) UNIQUE | Número da nota |
| `chave_acesso` | CHAR(44) UNIQUE | Chave de acesso NF-e (44 dígitos) |
| `valor_total` | DECIMAL(10,2) | Valor total faturado |

---

#### `caixa`
Controle de abertura e fechamento de caixa por funcionário e filial.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `saldo_inicial` | DECIMAL(12,2) | Fundo de troco inicial |
| `saldo_final` | DECIMAL(12,2) | Saldo ao fechar |
| `status` | ENUM | `aberto` / `fechado` |

---

### 🎁 Módulo: Promoções

---

#### `coupon`
Cupons de desconto com controle de validade, limite de uso e tipo (percentual ou valor fixo).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `codigo` | VARCHAR(30) UNIQUE | Código do cupom |
| `tipo` | ENUM | `percentual` ou `valor_fixo` |
| `valor` | DECIMAL(10,2) | Percentual (%) ou valor (R$) |
| `uso_maximo` | SMALLINT | Limite de utilizações (nulo = ilimitado) |
| `uso_atual` | SMALLINT | Contador automático de usos |
| `valido_de` / `valido_ate` | DATETIME | Janela de validade |

> **Trigger:** Validação automática ao aplicar cupom — rejeita se expirado, esgotado ou inativo.

---

#### `pedido_coupon`
Tabela de junção N:M entre pedidos e coupons aplicados.

---

#### `fidelidade_transacao`
Histórico completo de créditos, débitos e expirações de pontos por cliente.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `tipo` | ENUM | `credito` / `debito` / `expiracao` |
| `pontos` | INT UNSIGNED | Quantidade de pontos da transação |
| `descricao` | VARCHAR(200) | Ex: "Pedido #42", "Resgate 500pts" |

> **Regra:** 1 ponto a cada R$ 10,00 gastos. Creditado automaticamente ao fechar o pedido.

---

### 🛵 Módulo: Delivery

---

#### `entregador`
Cadastro de entregadores vinculados a uma filial (próprios ou terceirizados).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `veiculo` | VARCHAR(60) | Tipo de veículo |
| `placa` | VARCHAR(10) | Placa do veículo |

---

#### `pedido_delivery`
Extensão do pedido para entregas, com endereço, entregador, taxa e rastreamento.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `pedido_id` | FK PK | Um pedido = um delivery |
| `endereco_id` | FK | Endereço de entrega |
| `entregador_id` | FK (nullable) | Entregador alocado |
| `taxa_entrega` | DECIMAL(8,2) | Taxa cobrada |
| `previsao_entrega` | DATETIME | ETA |
| `status` | ENUM | `aguardando` / `despachado` / `entregue` / `cancelado` |

---

### 🎉 Módulo: Eventos

---

#### `evento`
Eventos realizados na filial (shows, noites temáticas, happy hour especial).

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `nome` | VARCHAR(150) | Nome do evento |
| `data_inicio` / `data_fim` | DATETIME | Período do evento |
| `capacidade` | SMALLINT | Máximo de participantes |
| `preco_ingresso` | DECIMAL(10,2) | `0.00` = evento gratuito |

---

## Regras de Negócio (Triggers)

| # | Trigger | Evento | Descrição |
|---|---------|--------|-----------|
| RN-01 | `trg_libera_mesa` | AFTER UPDATE pedido | Libera mesa (`livre`) ao fechar pedido |
| RN-02 | `trg_ocupa_mesa` | AFTER INSERT pedido | Ocupa mesa ao abrir pedido |
| RN-03 | `trg_recalc_subtotal_insert` | AFTER INSERT item_pedido | Recalcula subtotal do pedido |
| RN-03 | `trg_recalc_subtotal_update` | AFTER UPDATE item_pedido | Recalcula subtotal ao alterar item |
| RN-04 | `trg_baixa_estoque` | AFTER UPDATE item_pedido | Debita insumos da ficha técnica ao entregar item |
| RN-05 | `trg_pontos_fidelidade` | AFTER UPDATE pedido | Credita pontos ao fechar pedido (1pt/R$10) |
| RN-06 | `trg_incrementa_coupon` | AFTER INSERT pedido_coupon | Incrementa contador de uso do coupon |
| RN-07 | `trg_valida_coupon` | BEFORE INSERT pedido_coupon | Bloqueia coupon inativo, expirado ou esgotado |
| RN-08 | `trg_protege_pedido_fechado` | BEFORE DELETE pedido | Impede exclusão de pedido já fechado |

---

## Stored Procedures

### `sp_abrir_pedido`
Abre um pedido com validação de disponibilidade de mesa usando `SELECT ... FOR UPDATE` (lock transacional).

```sql
CALL sp_abrir_pedido(
    p_filial_id      INT,   -- ID da filial
    p_mesa_id        INT,   -- ID da mesa (deve estar 'livre' ou 'reservada')
    p_funcionario_id INT,   -- ID do garçom
    p_cliente_id     INT,   -- ID do cliente (pode ser NULL)
    OUT p_pedido_id  INT    -- Retorna o ID do pedido criado
);
```

### `sp_fechar_pedido`
Fecha o pedido e, opcionalmente, aplica a taxa de serviço de 10%.

```sql
CALL sp_fechar_pedido(
    p_pedido_id   INT,     -- ID do pedido
    p_aplicar_taxa TINYINT -- 1 = aplica 10%; 0 = sem taxa
);
```

### `sp_relatorio_financeiro`
Gera relatório de receita por dia em um intervalo de datas, com quebra por forma de pagamento.

```sql
CALL sp_relatorio_financeiro(
    p_filial_id INT,    -- ID da filial
    p_inicio    DATE,   -- Data inicial (ex: '2025-01-01')
    p_fim       DATE    -- Data final   (ex: '2025-01-31')
);
```

---

## Views

| View | Descrição |
|------|-----------|
| `vw_status_mesas` | Status atual de todas as mesas por filial e área |
| `vw_pedidos_abertos` | Pedidos ainda não fechados com totais e responsáveis |
| `vw_estoque_critico` | Insumos com estoque abaixo do mínimo configurado |
| `vw_ranking_produtos` | Produtos mais vendidos em quantidade e receita |
| `vw_receita_diaria` | Receita total por dia e filial (apenas pedidos fechados) |

---

## Índices

| Índice | Tabela | Coluna(s) | Objetivo |
|--------|--------|-----------|----------|
| `idx_produto_categoria` | produto | categoria_id | Filtro por categoria no cardápio |
| `idx_produto_disponivel` | produto | disponivel | Consulta de itens disponíveis |
| `idx_pedido_mesa` | pedido | mesa_id | Busca de pedido por mesa |
| `idx_pedido_status` | pedido | status | Filtro de pedidos em aberto |
| `idx_pedido_created` | pedido | created_at | Relatórios por data |
| `idx_item_pedido_pid` | item_pedido | pedido_id | JOIN eficiente com pedido |
| `idx_pagamento_pedido` | pagamento | pedido_id | Busca de pagamentos por pedido |
| `idx_reserva_data` | reserva | data_reserva | Consulta de reservas por data |
| `idx_reserva_status` | reserva | status | Filtro de reservas ativas |
| `idx_mov_estoque_insumo` | movimento_estoque | insumo_id | Histórico de insumo |
| `idx_cliente_cpf` | cliente | cpf | Busca de cliente por CPF |
| `idx_func_cargo` | funcionario | cargo_id | Listagem por cargo |

---

## Como Executar

### Pré-requisitos
- MySQL 8.0 ou superior
- Usuário com privilégios `CREATE`, `TRIGGER`, `PROCEDURE`, `VIEW`

### Importação

```bash
# Via terminal
mysql -u root -p < restaurante_bar_db.sql

# Ou via MySQL Workbench:
# File → Open SQL Script → restaurante_bar_db.sql → Execute (⚡)
```

### Verificação

```sql
USE restaurante_bar;
SHOW TABLES;          -- Lista as 25+ tabelas
SHOW TRIGGERS;        -- Lista os 8 triggers
SHOW PROCEDURE STATUS WHERE Db = 'restaurante_bar';
```

### Exemplo rápido de uso

```sql
-- 1. Abrir pedido na mesa 1
CALL sp_abrir_pedido(1, 1, 5, NULL, @pedido_id);
SELECT @pedido_id;

-- 2. Adicionar item
INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unitario)
VALUES (@pedido_id, 3, 2, 35.90);

-- 3. Ver pedidos abertos
SELECT * FROM vw_pedidos_abertos;

-- 4. Fechar pedido com taxa de serviço
CALL sp_fechar_pedido(@pedido_id, 1);

-- 5. Ver estoque crítico
SELECT * FROM vw_estoque_critico;
```

---

## Resumo Geral

| Item | Quantidade |
|------|-----------|
| Tabelas | 27 |
| Triggers | 8 |
| Stored Procedures | 3 |
| Views | 5 |
| Índices adicionais | 12 |
| Constraints CHECK | 15+ |
| Dados iniciais (seed) | Cargos, Categorias, Formas de Pagamento |

---

*Documentação gerada para o projeto `restaurante_bar` — versão 1.0*
