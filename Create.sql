-- ============================================================
--  SISTEMA DE RESTAURANTE & BAR — Modelagem Completa MySQL
--  Versão: 1.0
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS restaurante_bar;
CREATE DATABASE restaurante_bar
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE restaurante_bar;

-- ============================================================
-- 1. ENDEREÇO (reutilizável por clientes, fornecedores, filiais)
-- ============================================================
CREATE TABLE endereco (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    logradouro    VARCHAR(150) NOT NULL,
    numero        VARCHAR(10)  NOT NULL,
    complemento   VARCHAR(60),
    bairro        VARCHAR(80)  NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    estado        CHAR(2)      NOT NULL,
    cep           CHAR(9)      NOT NULL,   -- formato 00000-000
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cep FORMAT CHECK (cep REGEXP '^[0-9]{5}-[0-9]{3}$')
);

-- ============================================================
-- 2. FILIAL / UNIDADE
-- ============================================================
CREATE TABLE filial (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    cnpj          CHAR(18)     NOT NULL UNIQUE,   -- 00.000.000/0000-00
    telefone      VARCHAR(20),
    email         VARCHAR(120),
    endereco_id   INT UNSIGNED NOT NULL,
    ativa         TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_filial_endereco FOREIGN KEY (endereco_id) REFERENCES endereco(id)
);

-- ============================================================
-- 3. ÁREA / SETOR DO RESTAURANTE
-- ============================================================
CREATE TABLE area (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id   INT UNSIGNED NOT NULL,
    nome        VARCHAR(60)  NOT NULL,   -- Ex: Salão, Terraço, Bar, VIP, Delivery
    descricao   VARCHAR(200),
    ativa       TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_area_filial FOREIGN KEY (filial_id) REFERENCES filial(id)
);

-- ============================================================
-- 4. MESA
-- ============================================================
CREATE TABLE mesa (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    area_id         INT UNSIGNED NOT NULL,
    numero          SMALLINT UNSIGNED NOT NULL,
    capacidade      TINYINT UNSIGNED  NOT NULL DEFAULT 4,
    status          ENUM('livre','ocupada','reservada','manutencao') NOT NULL DEFAULT 'livre',
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_mesa_area FOREIGN KEY (area_id) REFERENCES area(id),
    CONSTRAINT uq_mesa_area UNIQUE (area_id, numero),
    CONSTRAINT chk_capacidade CHECK (capacidade BETWEEN 1 AND 50)
);

-- ============================================================
-- 5. CARGO
-- ============================================================
CREATE TABLE cargo (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(60)    NOT NULL UNIQUE,
    descricao   VARCHAR(200),
    salario_base DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- ============================================================
-- 6. FUNCIONÁRIO
-- ============================================================
CREATE TABLE funcionario (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED NOT NULL,
    cargo_id        INT UNSIGNED NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    cpf             CHAR(14)     NOT NULL UNIQUE,  -- 000.000.000-00
    rg              VARCHAR(20),
    data_nascimento DATE         NOT NULL,
    data_admissao   DATE         NOT NULL,
    data_demissao   DATE,
    telefone        VARCHAR(20),
    email           VARCHAR(120) UNIQUE,
    login           VARCHAR(60)  UNIQUE,
    senha_hash      VARCHAR(255),
    ativo           TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_func_filial  FOREIGN KEY (filial_id) REFERENCES filial(id),
    CONSTRAINT fk_func_cargo   FOREIGN KEY (cargo_id)  REFERENCES cargo(id),
    CONSTRAINT chk_demissao    CHECK (data_demissao IS NULL OR data_demissao >= data_admissao)
);

-- ============================================================
-- 7. CLIENTE
-- ============================================================
CREATE TABLE cliente (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    cpf             CHAR(14)     UNIQUE,
    data_nascimento DATE,
    telefone        VARCHAR(20),
    email           VARCHAR(120) UNIQUE,
    endereco_id     INT UNSIGNED,
    pontos_fidelidade INT UNSIGNED NOT NULL DEFAULT 0,
    ativo           TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente_end FOREIGN KEY (endereco_id) REFERENCES endereco(id)
);

-- ============================================================
-- 8. RESERVA
-- ============================================================
CREATE TABLE reserva (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED NOT NULL,
    cliente_id      INT UNSIGNED,
    mesa_id         INT UNSIGNED,
    funcionario_id  INT UNSIGNED NOT NULL,      -- quem cadastrou
    nome_contato    VARCHAR(100) NOT NULL,
    telefone_contato VARCHAR(20) NOT NULL,
    data_reserva    DATETIME     NOT NULL,
    num_pessoas     TINYINT UNSIGNED NOT NULL,
    status          ENUM('pendente','confirmada','cancelada','concluida') NOT NULL DEFAULT 'pendente',
    observacao      TEXT,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reserva_filial  FOREIGN KEY (filial_id)      REFERENCES filial(id),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (cliente_id)     REFERENCES cliente(id),
    CONSTRAINT fk_reserva_mesa    FOREIGN KEY (mesa_id)        REFERENCES mesa(id),
    CONSTRAINT fk_reserva_func    FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    CONSTRAINT chk_num_pessoas    CHECK (num_pessoas >= 1)
);

-- ============================================================
-- 9. CATEGORIA DE PRODUTO
-- ============================================================
CREATE TABLE categoria_produto (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(80)  NOT NULL UNIQUE,  -- Ex: Entrada, Prato Principal, Bebida Alcoólica…
    tipo        ENUM('comida','bebida','sobremesa','outro') NOT NULL DEFAULT 'comida',
    descricao   VARCHAR(200)
);

-- ============================================================
-- 10. PRODUTO / ITEM DO CARDÁPIO
-- ============================================================
CREATE TABLE produto (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categoria_id        INT UNSIGNED    NOT NULL,
    codigo              VARCHAR(30)     NOT NULL UNIQUE,
    nome                VARCHAR(120)    NOT NULL,
    descricao           TEXT,
    preco_venda         DECIMAL(10,2)   NOT NULL,
    custo_estimado      DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    tempo_preparo_min   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    disponivel          TINYINT(1)      NOT NULL DEFAULT 1,
    vendido_no_bar      TINYINT(1)      NOT NULL DEFAULT 0,
    vendido_no_salao    TINYINT(1)      NOT NULL DEFAULT 1,
    vendido_delivery    TINYINT(1)      NOT NULL DEFAULT 0,
    imagem_url          VARCHAR(300),
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_prod_categoria FOREIGN KEY (categoria_id) REFERENCES categoria_produto(id),
    CONSTRAINT chk_preco         CHECK (preco_venda  >= 0),
    CONSTRAINT chk_custo         CHECK (custo_estimado >= 0)
);

-- ============================================================
-- 11. COMBINAÇÃO / COMBO
-- ============================================================
CREATE TABLE combo (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    descricao   TEXT,
    preco       DECIMAL(10,2) NOT NULL,
    ativo       TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT chk_combo_preco CHECK (preco >= 0)
);

CREATE TABLE combo_item (
    combo_id    INT UNSIGNED NOT NULL,
    produto_id  INT UNSIGNED NOT NULL,
    quantidade  TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (combo_id, produto_id),
    CONSTRAINT fk_combo_item_combo   FOREIGN KEY (combo_id)   REFERENCES combo(id),
    CONSTRAINT fk_combo_item_produto FOREIGN KEY (produto_id) REFERENCES produto(id)
);

-- ============================================================
-- 12. FORNECEDOR
-- ============================================================
CREATE TABLE fornecedor (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(150) NOT NULL,
    nome_fantasia VARCHAR(150),
    cnpj        CHAR(18)     NOT NULL UNIQUE,
    telefone    VARCHAR(20),
    email       VARCHAR(120),
    endereco_id INT UNSIGNED,
    ativo       TINYINT(1)   NOT NULL DEFAULT 1,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_forn_end FOREIGN KEY (endereco_id) REFERENCES endereco(id)
);

-- ============================================================
-- 13. INSUMO / INGREDIENTE
-- ============================================================
CREATE TABLE insumo (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fornecedor_id   INT UNSIGNED,
    nome            VARCHAR(120) NOT NULL,
    unidade_medida  VARCHAR(20)  NOT NULL,  -- kg, L, un, cx...
    estoque_atual   DECIMAL(12,3) NOT NULL DEFAULT 0,
    estoque_minimo  DECIMAL(12,3) NOT NULL DEFAULT 0,
    custo_unitario  DECIMAL(10,4) NOT NULL DEFAULT 0,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_insumo_forn FOREIGN KEY (fornecedor_id) REFERENCES fornecedor(id),
    CONSTRAINT chk_estoque    CHECK (estoque_atual >= 0)
);

-- ============================================================
-- 14. FICHA TÉCNICA (insumos por produto)
-- ============================================================
CREATE TABLE ficha_tecnica (
    produto_id      INT UNSIGNED   NOT NULL,
    insumo_id       INT UNSIGNED   NOT NULL,
    quantidade      DECIMAL(10,4)  NOT NULL,
    PRIMARY KEY (produto_id, insumo_id),
    CONSTRAINT fk_ft_produto FOREIGN KEY (produto_id) REFERENCES produto(id),
    CONSTRAINT fk_ft_insumo  FOREIGN KEY (insumo_id)  REFERENCES insumo(id),
    CONSTRAINT chk_ft_qtd    CHECK (quantidade > 0)
);

-- ============================================================
-- 15. MOVIMENTO DE ESTOQUE
-- ============================================================
CREATE TABLE movimento_estoque (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    insumo_id       INT UNSIGNED  NOT NULL,
    funcionario_id  INT UNSIGNED,
    tipo            ENUM('entrada','saida','ajuste','perda') NOT NULL,
    quantidade      DECIMAL(12,3) NOT NULL,
    custo_unitario  DECIMAL(10,4),
    observacao      VARCHAR(255),
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mov_insumo FOREIGN KEY (insumo_id)      REFERENCES insumo(id),
    CONSTRAINT fk_mov_func   FOREIGN KEY (funcionario_id) REFERENCES funcionario(id)
);

-- ============================================================
-- 16. PEDIDO (comanda)
-- ============================================================
CREATE TABLE pedido (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED NOT NULL,
    mesa_id         INT UNSIGNED,               -- NULL = delivery / balcão
    cliente_id      INT UNSIGNED,
    funcionario_id  INT UNSIGNED NOT NULL,      -- garçom / atendente
    tipo            ENUM('mesa','balcao','delivery') NOT NULL DEFAULT 'mesa',
    status          ENUM('aberto','em_preparo','pronto','entregue','cancelado','fechado')
                    NOT NULL DEFAULT 'aberto',
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    desconto        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    taxa_servico    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total           DECIMAL(10,2) GENERATED ALWAYS AS (subtotal - desconto + taxa_servico) STORED,
    observacao      TEXT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ped_filial  FOREIGN KEY (filial_id)      REFERENCES filial(id),
    CONSTRAINT fk_ped_mesa    FOREIGN KEY (mesa_id)        REFERENCES mesa(id),
    CONSTRAINT fk_ped_cliente FOREIGN KEY (cliente_id)     REFERENCES cliente(id),
    CONSTRAINT fk_ped_func    FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    CONSTRAINT chk_ped_desc   CHECK (desconto >= 0),
    CONSTRAINT chk_ped_sub    CHECK (subtotal >= 0)
);

-- ============================================================
-- 17. ITEM DO PEDIDO
-- ============================================================
CREATE TABLE item_pedido (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pedido_id       INT UNSIGNED     NOT NULL,
    produto_id      INT UNSIGNED,                -- NULL se for combo
    combo_id        INT UNSIGNED,
    quantidade      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    preco_unitario  DECIMAL(10,2)    NOT NULL,
    desconto        DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
    subtotal        DECIMAL(10,2)    GENERATED ALWAYS AS (quantidade * preco_unitario - desconto) STORED,
    status          ENUM('pendente','em_preparo','pronto','entregue','cancelado') NOT NULL DEFAULT 'pendente',
    observacao      VARCHAR(255),
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ip_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido(id),
    CONSTRAINT fk_ip_produto FOREIGN KEY (produto_id) REFERENCES produto(id),
    CONSTRAINT fk_ip_combo   FOREIGN KEY (combo_id)   REFERENCES combo(id),
    CONSTRAINT chk_ip_qtd    CHECK (quantidade >= 1),
    CONSTRAINT chk_ip_preco  CHECK (preco_unitario >= 0),
    -- Deve ter produto OU combo (não os dois, não nenhum)
    CONSTRAINT chk_ip_origem CHECK (
        (produto_id IS NOT NULL AND combo_id IS NULL) OR
        (produto_id IS NULL     AND combo_id IS NOT NULL)
    )
);

-- ============================================================
-- 18. FORMA DE PAGAMENTO
-- ============================================================
CREATE TABLE forma_pagamento (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(60)   NOT NULL UNIQUE,  -- Dinheiro, Crédito, Débito, Pix…
    ativa       TINYINT(1)    NOT NULL DEFAULT 1
);

-- ============================================================
-- 19. PAGAMENTO
-- ============================================================
CREATE TABLE pagamento (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pedido_id           INT UNSIGNED   NOT NULL,
    forma_pagamento_id  INT UNSIGNED   NOT NULL,
    valor               DECIMAL(10,2)  NOT NULL,
    troco               DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    nsu                 VARCHAR(30),            -- para cartão
    status              ENUM('pendente','aprovado','recusado','estornado') NOT NULL DEFAULT 'pendente',
    created_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pag_pedido FOREIGN KEY (pedido_id)          REFERENCES pedido(id),
    CONSTRAINT fk_pag_forma  FOREIGN KEY (forma_pagamento_id) REFERENCES forma_pagamento(id),
    CONSTRAINT chk_pag_valor CHECK (valor > 0)
);

-- ============================================================
-- 20. NOTA FISCAL (simplificada)
-- ============================================================
CREATE TABLE nota_fiscal (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pedido_id       INT UNSIGNED   NOT NULL UNIQUE,
    numero          VARCHAR(20)    NOT NULL UNIQUE,
    serie           CHAR(3)        NOT NULL DEFAULT '001',
    chave_acesso    CHAR(44)       UNIQUE,
    valor_total     DECIMAL(10,2)  NOT NULL,
    emitida_em      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_nf_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id)
);

-- ============================================================
-- 21. COUPON / DESCONTO
-- ============================================================
CREATE TABLE coupon (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(30)   NOT NULL UNIQUE,
    tipo            ENUM('percentual','valor_fixo') NOT NULL,
    valor           DECIMAL(10,2) NOT NULL,
    uso_maximo      SMALLINT UNSIGNED,
    uso_atual       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    valido_de       DATETIME,
    valido_ate      DATETIME,
    ativo           TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT chk_coupon_val CHECK (valor > 0),
    CONSTRAINT chk_coupon_datas CHECK (valido_de IS NULL OR valido_ate IS NULL OR valido_de <= valido_ate)
);

CREATE TABLE pedido_coupon (
    pedido_id   INT UNSIGNED NOT NULL,
    coupon_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (pedido_id, coupon_id),
    CONSTRAINT fk_pc_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id),
    CONSTRAINT fk_pc_coupon FOREIGN KEY (coupon_id) REFERENCES coupon(id)
);

-- ============================================================
-- 22. PROGRAMA DE FIDELIDADE
-- ============================================================
CREATE TABLE fidelidade_transacao (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id      INT UNSIGNED NOT NULL,
    pedido_id       INT UNSIGNED,
    tipo            ENUM('credito','debito','expiracao') NOT NULL,
    pontos          INT UNSIGNED NOT NULL,
    descricao       VARCHAR(200),
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fid_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    CONSTRAINT fk_fid_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido(id)
);

-- ============================================================
-- 23. DELIVERY
-- ============================================================
CREATE TABLE entregador (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    cpf             CHAR(14)     NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    veiculo         VARCHAR(60),
    placa           VARCHAR(10),
    ativo           TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_entr_filial FOREIGN KEY (filial_id) REFERENCES filial(id)
);

CREATE TABLE pedido_delivery (
    pedido_id       INT UNSIGNED NOT NULL PRIMARY KEY,
    endereco_id     INT UNSIGNED NOT NULL,
    entregador_id   INT UNSIGNED,
    taxa_entrega    DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    previsao_entrega DATETIME,
    entregue_em     DATETIME,
    status          ENUM('aguardando','despachado','entregue','cancelado') NOT NULL DEFAULT 'aguardando',
    CONSTRAINT fk_del_pedido    FOREIGN KEY (pedido_id)    REFERENCES pedido(id),
    CONSTRAINT fk_del_end       FOREIGN KEY (endereco_id)  REFERENCES endereco(id),
    CONSTRAINT fk_del_entregador FOREIGN KEY (entregador_id) REFERENCES entregador(id)
);

-- ============================================================
-- 24. EVENTO
-- ============================================================
CREATE TABLE evento (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED NOT NULL,
    nome            VARCHAR(150) NOT NULL,
    descricao       TEXT,
    data_inicio     DATETIME     NOT NULL,
    data_fim        DATETIME     NOT NULL,
    capacidade      SMALLINT UNSIGNED,
    preco_ingresso  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ativo           TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT fk_evento_filial FOREIGN KEY (filial_id) REFERENCES filial(id),
    CONSTRAINT chk_evento_datas CHECK (data_fim > data_inicio)
);

-- ============================================================
-- 25. AVALIAÇÃO / FEEDBACK
-- ============================================================
CREATE TABLE avaliacao (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pedido_id       INT UNSIGNED NOT NULL,
    cliente_id      INT UNSIGNED,
    nota_comida     TINYINT UNSIGNED NOT NULL,
    nota_atendimento TINYINT UNSIGNED NOT NULL,
    nota_ambiente   TINYINT UNSIGNED NOT NULL,
    comentario      TEXT,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_aval_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido(id),
    CONSTRAINT fk_aval_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    CONSTRAINT chk_nota_c  CHECK (nota_comida      BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_a  CHECK (nota_atendimento BETWEEN 1 AND 5),
    CONSTRAINT chk_nota_am CHECK (nota_ambiente     BETWEEN 1 AND 5)
);

-- ============================================================
-- 26. TURNO DE TRABALHO
-- ============================================================
CREATE TABLE turno (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    funcionario_id  INT UNSIGNED NOT NULL,
    filial_id       INT UNSIGNED NOT NULL,
    entrada         DATETIME     NOT NULL,
    saida           DATETIME,
    observacao      VARCHAR(200),
    CONSTRAINT fk_turno_func   FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    CONSTRAINT fk_turno_filial FOREIGN KEY (filial_id)      REFERENCES filial(id),
    CONSTRAINT chk_turno_saida CHECK (saida IS NULL OR saida > entrada)
);

-- ============================================================
-- 27. CAIXA
-- ============================================================
CREATE TABLE caixa (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filial_id       INT UNSIGNED   NOT NULL,
    funcionario_id  INT UNSIGNED   NOT NULL,
    abertura        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fechamento      DATETIME,
    saldo_inicial   DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    saldo_final     DECIMAL(12,2),
    status          ENUM('aberto','fechado') NOT NULL DEFAULT 'aberto',
    observacao      TEXT,
    CONSTRAINT fk_caixa_filial FOREIGN KEY (filial_id)      REFERENCES filial(id),
    CONSTRAINT fk_caixa_func   FOREIGN KEY (funcionario_id) REFERENCES funcionario(id),
    CONSTRAINT chk_caixa_fech  CHECK (fechamento IS NULL OR fechamento > abertura)
);

-- ============================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================
CREATE INDEX idx_produto_categoria   ON produto(categoria_id);
CREATE INDEX idx_produto_disponivel  ON produto(disponivel);
CREATE INDEX idx_pedido_mesa         ON pedido(mesa_id);
CREATE INDEX idx_pedido_status       ON pedido(status);
CREATE INDEX idx_pedido_created      ON pedido(created_at);
CREATE INDEX idx_item_pedido_pid     ON item_pedido(pedido_id);
CREATE INDEX idx_pagamento_pedido    ON pagamento(pedido_id);
CREATE INDEX idx_reserva_data        ON reserva(data_reserva);
CREATE INDEX idx_reserva_status      ON reserva(status);
CREATE INDEX idx_mov_estoque_insumo  ON movimento_estoque(insumo_id);
CREATE INDEX idx_cliente_cpf         ON cliente(cpf);
CREATE INDEX idx_func_cargo          ON funcionario(cargo_id);

-- ============================================================
-- TRIGGERS — REGRAS DE NEGÓCIO AUTOMÁTICAS
-- ============================================================

DELIMITER $$

-- RN-01: Ao fechar pedido, atualiza status da mesa para 'livre'
CREATE TRIGGER trg_libera_mesa
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
    IF NEW.status = 'fechado' AND OLD.status <> 'fechado' AND NEW.mesa_id IS NOT NULL THEN
        UPDATE mesa SET status = 'livre' WHERE id = NEW.mesa_id;
    END IF;
END$$

-- RN-02: Ao abrir pedido em mesa, muda status da mesa para 'ocupada'
CREATE TRIGGER trg_ocupa_mesa
AFTER INSERT ON pedido
FOR EACH ROW
BEGIN
    IF NEW.mesa_id IS NOT NULL AND NEW.status = 'aberto' THEN
        UPDATE mesa SET status = 'ocupada' WHERE id = NEW.mesa_id;
    END IF;
END$$

-- RN-03: Recalcula subtotal do pedido ao inserir/atualizar item
CREATE TRIGGER trg_recalc_subtotal_insert
AFTER INSERT ON item_pedido
FOR EACH ROW
BEGIN
    UPDATE pedido
    SET subtotal = (
        SELECT COALESCE(SUM(subtotal), 0) FROM item_pedido
        WHERE pedido_id = NEW.pedido_id AND status <> 'cancelado'
    )
    WHERE id = NEW.pedido_id;
END$$

CREATE TRIGGER trg_recalc_subtotal_update
AFTER UPDATE ON item_pedido
FOR EACH ROW
BEGIN
    UPDATE pedido
    SET subtotal = (
        SELECT COALESCE(SUM(subtotal), 0) FROM item_pedido
        WHERE pedido_id = NEW.pedido_id AND status <> 'cancelado'
    )
    WHERE id = NEW.pedido_id;
END$$

-- RN-04: Baixa estoque de insumos ao confirmar item como entregue
CREATE TRIGGER trg_baixa_estoque
AFTER UPDATE ON item_pedido
FOR EACH ROW
BEGIN
    IF NEW.status = 'entregue' AND OLD.status <> 'entregue' AND NEW.produto_id IS NOT NULL THEN
        INSERT INTO movimento_estoque (insumo_id, tipo, quantidade, observacao, created_at)
        SELECT ft.insumo_id, 'saida', ft.quantidade * NEW.quantidade,
               CONCAT('Pedido #', NEW.pedido_id, ' item #', NEW.id),
               NOW()
        FROM ficha_tecnica ft
        WHERE ft.produto_id = NEW.produto_id;

        UPDATE insumo i
        JOIN ficha_tecnica ft ON ft.insumo_id = i.id AND ft.produto_id = NEW.produto_id
        SET i.estoque_atual = i.estoque_atual - (ft.quantidade * NEW.quantidade);
    END IF;
END$$

-- RN-05: Credita pontos de fidelidade ao cliente ao fechar pedido
CREATE TRIGGER trg_pontos_fidelidade
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
    DECLARE pts INT;
    IF NEW.status = 'fechado' AND OLD.status <> 'fechado' AND NEW.cliente_id IS NOT NULL THEN
        SET pts = FLOOR(NEW.total / 10);  -- 1 ponto a cada R$ 10
        IF pts > 0 THEN
            UPDATE cliente SET pontos_fidelidade = pontos_fidelidade + pts WHERE id = NEW.cliente_id;
            INSERT INTO fidelidade_transacao (cliente_id, pedido_id, tipo, pontos, descricao)
            VALUES (NEW.cliente_id, NEW.id, 'credito', pts, CONCAT('Pedido #', NEW.id));
        END IF;
    END IF;
END$$

-- RN-06: Incrementa uso do coupon ao ser aplicado
CREATE TRIGGER trg_incrementa_coupon
AFTER INSERT ON pedido_coupon
FOR EACH ROW
BEGIN
    UPDATE coupon SET uso_atual = uso_atual + 1 WHERE id = NEW.coupon_id;
END$$

-- RN-07: Impede uso de coupon expirado ou esgotado
CREATE TRIGGER trg_valida_coupon
BEFORE INSERT ON pedido_coupon
FOR EACH ROW
BEGIN
    DECLARE v_ativo      TINYINT;
    DECLARE v_valido_ate DATETIME;
    DECLARE v_uso_max    SMALLINT;
    DECLARE v_uso_atual  SMALLINT;

    SELECT ativo, valido_ate, uso_maximo, uso_atual
    INTO v_ativo, v_valido_ate, v_uso_max, v_uso_atual
    FROM coupon WHERE id = NEW.coupon_id;

    IF v_ativo = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Coupon inativo.';
    END IF;
    IF v_valido_ate IS NOT NULL AND v_valido_ate < NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Coupon expirado.';
    END IF;
    IF v_uso_max IS NOT NULL AND v_uso_atual >= v_uso_max THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Coupon atingiu o limite de usos.';
    END IF;
END$$

-- RN-08: Impede exclusão de pedido fechado
CREATE TRIGGER trg_protege_pedido_fechado
BEFORE DELETE ON pedido
FOR EACH ROW
BEGIN
    IF OLD.status = 'fechado' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido fechado não pode ser excluído.';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- VIEWS ÚTEIS
-- ============================================================

-- Posição atual das mesas
CREATE VIEW vw_status_mesas AS
SELECT m.id, f.nome AS filial, a.nome AS area, m.numero, m.capacidade, m.status
FROM mesa m
JOIN area a    ON a.id = m.area_id
JOIN filial f  ON f.id = a.filial_id
ORDER BY f.nome, a.nome, m.numero;

-- Pedidos em aberto com total
CREATE VIEW vw_pedidos_abertos AS
SELECT p.id, f.nome AS filial, m.numero AS mesa,
       c.nome AS cliente, fun.nome AS garcom,
       p.tipo, p.status, p.subtotal, p.desconto, p.taxa_servico, p.total,
       p.created_at
FROM pedido p
JOIN filial f ON f.id = p.filial_id
LEFT JOIN mesa m ON m.id = p.mesa_id
LEFT JOIN cliente c ON c.id = p.cliente_id
JOIN funcionario fun ON fun.id = p.funcionario_id
WHERE p.status NOT IN ('fechado','cancelado');

-- Produtos com estoque crítico
CREATE VIEW vw_estoque_critico AS
SELECT i.id, i.nome, i.unidade_medida,
       i.estoque_atual, i.estoque_minimo,
       f.razao_social AS fornecedor
FROM insumo i
LEFT JOIN fornecedor f ON f.id = i.fornecedor_id
WHERE i.estoque_atual <= i.estoque_minimo;

-- Ranking de produtos mais vendidos
CREATE VIEW vw_ranking_produtos AS
SELECT pr.id, pr.nome,
       SUM(ip.quantidade) AS total_vendido,
       SUM(ip.subtotal)   AS receita_total
FROM item_pedido ip
JOIN produto pr ON pr.id = ip.produto_id
JOIN pedido p   ON p.id  = ip.pedido_id
WHERE p.status = 'fechado' AND ip.status = 'entregue'
GROUP BY pr.id, pr.nome
ORDER BY total_vendido DESC;

-- Receita por dia
CREATE VIEW vw_receita_diaria AS
SELECT DATE(p.created_at) AS data, f.nome AS filial,
       COUNT(p.id) AS num_pedidos,
       SUM(p.total) AS receita_total
FROM pedido p
JOIN filial f ON f.id = p.filial_id
WHERE p.status = 'fechado'
GROUP BY DATE(p.created_at), f.id, f.nome
ORDER BY data DESC;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- SP: Abre um novo pedido de mesa
CREATE PROCEDURE sp_abrir_pedido(
    IN p_filial_id       INT UNSIGNED,
    IN p_mesa_id         INT UNSIGNED,
    IN p_funcionario_id  INT UNSIGNED,
    IN p_cliente_id      INT UNSIGNED,
    OUT p_pedido_id      INT UNSIGNED
)
BEGIN
    DECLARE v_status_mesa VARCHAR(20);

    SELECT status INTO v_status_mesa FROM mesa WHERE id = p_mesa_id FOR UPDATE;

    IF v_status_mesa NOT IN ('livre','reservada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mesa não está disponível.';
    END IF;

    INSERT INTO pedido (filial_id, mesa_id, cliente_id, funcionario_id, tipo)
    VALUES (p_filial_id, p_mesa_id, p_cliente_id, p_funcionario_id, 'mesa');

    SET p_pedido_id = LAST_INSERT_ID();
END$$

-- SP: Fecha pedido e aplica taxa de serviço (10%)
CREATE PROCEDURE sp_fechar_pedido(
    IN p_pedido_id INT UNSIGNED,
    IN p_aplicar_taxa TINYINT   -- 1 = sim, 0 = não
)
BEGIN
    DECLARE v_sub DECIMAL(10,2);

    SELECT subtotal INTO v_sub FROM pedido WHERE id = p_pedido_id;

    IF p_aplicar_taxa = 1 THEN
        UPDATE pedido
        SET taxa_servico = ROUND(v_sub * 0.10, 2),
            status       = 'fechado'
        WHERE id = p_pedido_id;
    ELSE
        UPDATE pedido SET status = 'fechado', taxa_servico = 0 WHERE id = p_pedido_id;
    END IF;
END$$

-- SP: Relatório financeiro por período
CREATE PROCEDURE sp_relatorio_financeiro(
    IN p_filial_id INT UNSIGNED,
    IN p_inicio    DATE,
    IN p_fim       DATE
)
BEGIN
    SELECT
        DATE(p.created_at)      AS data,
        COUNT(DISTINCT p.id)    AS pedidos,
        SUM(p.subtotal)         AS subtotal,
        SUM(p.desconto)         AS descontos,
        SUM(p.taxa_servico)     AS taxa_servico,
        SUM(p.total)            AS total_liquido,
        SUM(CASE WHEN fp.nome = 'Dinheiro' THEN pg.valor ELSE 0 END) AS dinheiro,
        SUM(CASE WHEN fp.nome LIKE '%Crédito%' THEN pg.valor ELSE 0 END) AS credito,
        SUM(CASE WHEN fp.nome LIKE '%Débito%' THEN pg.valor ELSE 0 END) AS debito,
        SUM(CASE WHEN fp.nome = 'Pix' THEN pg.valor ELSE 0 END) AS pix
    FROM pedido p
    LEFT JOIN pagamento pg ON pg.pedido_id = p.id AND pg.status = 'aprovado'
    LEFT JOIN forma_pagamento fp ON fp.id = pg.forma_pagamento_id
    WHERE p.filial_id = p_filial_id
      AND p.status    = 'fechado'
      AND DATE(p.created_at) BETWEEN p_inicio AND p_fim
    GROUP BY DATE(p.created_at)
    ORDER BY data;
END$$

DELIMITER ;

-- ============================================================
-- DADOS INICIAIS (seed)
-- ============================================================

INSERT INTO cargo (nome, salario_base) VALUES
    ('Gerente', 5000.00),
    ('Chefe de Cozinha', 4500.00),
    ('Cozinheiro', 2800.00),
    ('Barman', 2500.00),
    ('Garçom', 1800.00),
    ('Caixa', 2000.00),
    ('Auxiliar de Cozinha', 1500.00),
    ('Entregador', 1600.00);

INSERT INTO categoria_produto (nome, tipo) VALUES
    ('Entradas', 'comida'),
    ('Pratos Principais', 'comida'),
    ('Grelhados', 'comida'),
    ('Sobremesas', 'sobremesa'),
    ('Cervejas', 'bebida'),
    ('Drinks & Coquetéis', 'bebida'),
    ('Refrigerantes', 'bebida'),
    ('Sucos Naturais', 'bebida'),
    ('Vinhos', 'bebida'),
    ('Destilados', 'bebida');

INSERT INTO forma_pagamento (nome) VALUES
    ('Dinheiro'),
    ('Cartão de Crédito'),
    ('Cartão de Débito'),
    ('Pix'),
    ('Vale-Refeição'),
    ('Cortesia');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
