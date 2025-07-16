-- =============================================================================
-- | SCRIPT COMPLETO - PROJETO PORTAL DA AGRICULTURA E MEIO AMBIENTE             |
-- | GRUPO 21 - GUSTAVO DA SILVA GARCIA (RA 822522)                              |
-- |                                                                           |
-- | Contém: DDL, Índices, DML, Procedures, Functions e Triggers.              |
-- | SGBD: PostgreSQL                                                          |
-- |                                                                           |
-- | INSTRUÇÃO: Crie um banco de dados vazio (ex: CREATE DATABASE db_agricultura_sc;) |
-- | e execute este script completo nele.                                      |
-- =============================================================================


-- ===================================================================
-- SEÇÃO 1: CRIAÇÃO DE TABELAS (DDL)
-- ===================================================================

-- Tabela PESSOA: Entidade generalizada para Pessoas Fisicas e Juridicas.
CREATE TABLE PESSOA (
    id_pessoa SERIAL PRIMARY KEY,
    cep VARCHAR(9) NOT NULL,
    complemento VARCHAR(100),
    numero VARCHAR(10),
    email VARCHAR(255) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    tipo_pessoa CHAR(1) NOT NULL CHECK (tipo_pessoa IN ('F', 'J'))
);
COMMENT ON TABLE PESSOA IS 'Armazena dados comuns a pessoas fisicas e juridicas.';

-- Tabela PESSOA_FISICA: Especializacao de PESSOA.
CREATE TABLE PESSOA_FISICA (
    id_pessoa INTEGER PRIMARY KEY,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    nome_completo VARCHAR(255) NOT NULL,
    data_nascimento DATE,
    CONSTRAINT fk_pessoa_fisica FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa) ON DELETE CASCADE
);
COMMENT ON TABLE PESSOA_FISICA IS 'Dados especificos de pessoas fisicas.';

-- Tabela PESSOA_JURIDICA: Especializacao de PESSOA.
CREATE TABLE PESSOA_JURIDICA (
    id_pessoa INTEGER PRIMARY KEY,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    razao_social VARCHAR(255) NOT NULL,
    nome_fantasia VARCHAR(255),
    CONSTRAINT fk_pessoa_juridica FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa) ON DELETE CASCADE
);
COMMENT ON TABLE PESSOA_JURIDICA IS 'Dados especificos de pessoas juridicas.';

-- Tabela IMOVEL_RURAL: Propriedades rurais do municipio.
CREATE TABLE IMOVEL_RURAL (
    id_imovel_rural SERIAL PRIMARY KEY,
    nome_imovel VARCHAR(150) NOT NULL,
    area_total_ha NUMERIC(10, 2) NOT NULL CHECK (area_total_ha > 0),
    localizacao TEXT, -- Em um cenario real, usaria-se um tipo Geometrico (PostGIS)
    cep VARCHAR(9) NOT NULL,
    data_cadastro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_modificacao TIMESTAMP WITH TIME ZONE
);
COMMENT ON TABLE IMOVEL_RURAL IS 'Cadastro de propriedades rurais.';

-- Tabela PROPRIEDADE: Tabela associativa entre PESSOA e IMOVEL_RURAL (N:M).
CREATE TABLE PROPRIEDADE (
    id_propriedade SERIAL PRIMARY KEY,
    id_pessoa INTEGER NOT NULL,
    id_imovel_rural INTEGER NOT NULL,
    data_aquisicao DATE NOT NULL,
    percentual_propriedade NUMERIC(5, 2) NOT NULL CHECK (percentual_propriedade > 0 AND percentual_propriedade <= 100),
    CONSTRAINT fk_propriedade_pessoa FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa),
    CONSTRAINT fk_propriedade_imovel FOREIGN KEY (id_imovel_rural) REFERENCES IMOVEL_RURAL (id_imovel_rural),
    UNIQUE (id_pessoa, id_imovel_rural)
);
COMMENT ON TABLE PROPRIEDADE IS 'Relaciona proprietarios aos seus imoveis rurais.';

-- Tabela AGROTOXICO: Catalogo de agrotoxicos.
CREATE TABLE AGROTOXICO (
    id_agrotoxico SERIAL PRIMARY KEY,
    nome_comercial VARCHAR(100) NOT NULL UNIQUE,
    fabricante VARCHAR(100)
);
COMMENT ON TABLE AGROTOXICO IS 'Catalogo de agrotoxicos utilizados.';

-- Tabela PRODUCAO_AGRICOLA: Registros de cultivos agricolas.
CREATE TABLE PRODUCAO_AGRICOLA (
    id_producao_agricola SERIAL PRIMARY KEY,
    id_imovel_rural INTEGER NOT NULL,
    cultura_plantada VARCHAR(100) NOT NULL,
    area_cultivada_ha NUMERIC(10, 2) NOT NULL,
    data_plantio DATE NOT NULL,
    data_colheita_prevista DATE,
    safra VARCHAR(20),
    status_producao VARCHAR(20) NOT NULL CHECK (status_producao IN ('Planejada', 'Em Andamento', 'Colhida', 'Cancelada')),
    CONSTRAINT fk_prod_agricola_imovel FOREIGN KEY (id_imovel_rural) REFERENCES IMOVEL_RURAL (id_imovel_rural)
);
COMMENT ON TABLE PRODUCAO_AGRICOLA IS 'Informacoes sobre as producoes agricolas nos imoveis.';

-- Tabela APLICACAO_AGROTOXICO: Tabela associativa entre PRODUCAO_AGRICOLA e AGROTOXICO.
CREATE TABLE APLICACAO_AGROTOXICO (
    id_aplicacao SERIAL PRIMARY KEY,
    id_producao_agricola INTEGER NOT NULL,
    id_agrotoxico INTEGER NOT NULL,
    data_aplicacao DATE NOT NULL,
    dose_utilizada VARCHAR(50) NOT NULL, -- Ex: '2 L/ha'
    metodo_aplicacao VARCHAR(100),
    CONSTRAINT fk_aplicacao_producao FOREIGN KEY (id_producao_agricola) REFERENCES PRODUCAO_AGRICOLA (id_producao_agricola),
    CONSTRAINT fk_aplicacao_agrotoxico FOREIGN KEY (id_agrotoxico) REFERENCES AGROTOXICO (id_agrotoxico)
);
COMMENT ON TABLE APLICACAO_AGROTOXICO IS 'Registro do uso de agrotoxicos em uma producao.';

-- Tabela PRODUCAO_PECUARIA: Registros de criacao de animais.
CREATE TABLE PRODUCAO_PECUARIA (
    id_producao_pecuaria SERIAL PRIMARY KEY,
    id_imovel_rural INTEGER NOT NULL,
    tipo_criacao VARCHAR(100) NOT NULL, -- Ex: 'Bovino de Corte', 'Galinha Poedeira'
    qtd_animais INTEGER NOT NULL CHECK (qtd_animais >= 0),
    raca VARCHAR(100),
    finalidade VARCHAR(100), -- Ex: 'Leite', 'Carne', 'Ovos'
    CONSTRAINT fk_prod_pecuaria_imovel FOREIGN KEY (id_imovel_rural) REFERENCES IMOVEL_RURAL (id_imovel_rural)
);
COMMENT ON TABLE PRODUCAO_PECUARIA IS 'Informacoes sobre as producoes pecuarias nos imoveis.';

-- Tabela RECURSO_HIDRICO: Catalogo de rios, pocos, etc.
CREATE TABLE RECURSO_HIDRICO (
    id_recurso_hidrico SERIAL PRIMARY KEY,
    nome_recurso VARCHAR(100) NOT NULL,
    tipo_recurso VARCHAR(50) NOT NULL CHECK (tipo_recurso IN ('Rio', 'Corrego', 'Poco Artesiano', 'Lagoa', 'Nascente'))
);
COMMENT ON TABLE RECURSO_HIDRICO IS 'Catalogo de corpos d''agua relevantes.';

-- Tabela PONTO_CAPTACAO_AGUA: Locais de captacao de agua em um imovel.
CREATE TABLE PONTO_CAPTACAO_AGUA (
    id_ponto_captacao SERIAL PRIMARY KEY,
    id_imovel_rural INTEGER NOT NULL,
    id_recurso_hidrico INTEGER NOT NULL,
    coordenadas_ponto VARCHAR(100), -- Ex: '-22.0154, -47.8911' (Lat/Lon)
    tipo_ponto VARCHAR(50), -- Ex: 'Bomba', 'Barramento'
    descricao_local_ponto TEXT,
    CONSTRAINT fk_ponto_imovel FOREIGN KEY (id_imovel_rural) REFERENCES IMOVEL_RURAL (id_imovel_rural),
    CONSTRAINT fk_ponto_recurso FOREIGN KEY (id_recurso_hidrico) REFERENCES RECURSO_HIDRICO (id_recurso_hidrico)
);
COMMENT ON TABLE PONTO_CAPTACAO_AGUA IS 'Pontos especificos de onde a agua e captada.';

-- Tabela USO_RECURSO_HIDRICO: Associacao entre PRODUCAO e RECURSO_HIDRICO.
CREATE TABLE USO_RECURSO_HIDRICO (
    id_uso_recurso SERIAL PRIMARY KEY,
    id_producao_agricola INTEGER NOT NULL,
    id_ponto_captacao INTEGER NOT NULL,
    data_inicio_uso DATE NOT NULL,
    volume_agua_captado_m3 NUMERIC(10, 2),
    tipo_irrigacao_usado VARCHAR(50), -- Ex: 'Gotejamento', 'Aspersao'
    CONSTRAINT fk_uso_producao FOREIGN KEY (id_producao_agricola) REFERENCES PRODUCAO_AGRICOLA (id_producao_agricola),
    CONSTRAINT fk_uso_ponto_captacao FOREIGN KEY (id_ponto_captacao) REFERENCES PONTO_CAPTACAO_AGUA (id_ponto_captacao),
    UNIQUE (id_producao_agricola, id_ponto_captacao)
);
COMMENT ON TABLE USO_RECURSO_HIDRICO IS 'Registro do uso de agua de um ponto de captacao por uma producao agricola.';

-- Tabela LOG_PROPRIEDADE: Para auditoria de mudancas na tabela PROPRIEDADE.
CREATE TABLE LOG_PROPRIEDADE (
    id_log SERIAL PRIMARY KEY,
    operacao CHAR(1) NOT NULL, -- I: Insert, U: Update, D: Delete
    usuario_db VARCHAR(100) NOT NULL,
    timestamp_log TIMESTAMP NOT NULL,
    id_propriedade_antigo INTEGER,
    id_pessoa_antigo INTEGER,
    id_imovel_antigo INTEGER,
    percentual_antigo NUMERIC,
    id_propriedade_novo INTEGER,
    id_pessoa_novo INTEGER,
    id_imovel_novo INTEGER,
    percentual_novo NUMERIC
);


-- ===================================================================
-- SEÇÃO 2: CRIAÇÃO DE ÍNDICES
-- ===================================================================

-- Indice no CPF da tabela PESSOA_FISICA para agilizar buscas por documento.
CREATE INDEX idx_pessoa_fisica_cpf ON PESSOA_FISICA(cpf);

-- Indice no CNPJ da tabela PESSOA_JURIDICA.
CREATE INDEX idx_pessoa_juridica_cnpj ON PESSOA_JURIDICA(cnpj);

-- Indice no nome do imovel rural para facilitar a busca por nome da propriedade.
CREATE INDEX idx_imovel_rural_nome ON IMOVEL_RURAL(nome_imovel);

-- Indice na cultura plantada para otimizar filtros por tipo de cultivo.
CREATE INDEX idx_producao_agricola_cultura ON PRODUCAO_AGRICOLA(cultura_plantada);

-- Indice na chave estrangeira id_imovel_rural na tabela PROPRIEDADE.
CREATE INDEX idx_propriedade_imovel ON PROPRIEDADE(id_imovel_rural);

-- Indice na chave estrangeira id_imovel_rural na tabela PRODUCAO_AGRICOLA.
CREATE INDEX idx_producao_agricola_imovel ON PRODUCAO_AGRICOLA(id_imovel_rural);

-- Indice no tipo do recurso hidrico.
CREATE INDEX idx_recurso_hidrico_tipo ON RECURSO_HIDRICO(tipo_recurso);


-- ===================================================================
-- SEÇÃO 3: INSERÇÃO DE DADOS DE TESTE (DML)
-- ===================================================================

-- -------------------------------------------------------------------
-- Inserindo Pessoas (Fisicas e Juridicas)
-- -------------------------------------------------------------------
-- Pessoas Fisicas
INSERT INTO PESSOA (id_pessoa, cep, email, tipo_pessoa) VALUES 
(1, '13560-000', 'joao.silva@email.com', 'F'), (2, '13561-123', 'maria.souza@email.com', 'F'),
(3, '13562-200', 'carlos.pereira@email.com', 'F'), (4, '13563-300', 'ana.oliveira@email.com', 'F'),
(5, '13564-400', 'lucas.martins@email.com', 'F'), (6, '13565-500', 'fernanda.costa@email.com', 'F'),
(7, '13566-600', 'pedro.almeida@email.com', 'F'), (8, '13567-700', 'juliana.santos@email.com', 'F');
INSERT INTO PESSOA_FISICA (id_pessoa, cpf, nome_completo, data_nascimento) VALUES
(1, '111.222.333-44', 'Joao da Silva', '1980-05-15'), (2, '222.333.444-55', 'Maria de Souza', '1992-11-20'),
(3, '333.444.555-66', 'Carlos Pereira', '1975-02-10'), (4, '444.555.666-77', 'Ana Oliveira', '1988-09-01'),
(5, '555.666.777-88', 'Lucas Martins', '1995-07-25'), (6, '666.777.888-99', 'Fernanda Costa', '1990-03-30'),
(7, '777.888.999-00', 'Pedro Almeida', '1968-12-05'), (8, '888.999.000-11', 'Juliana Santos', '2000-01-18');

-- Pessoas Juridicas
INSERT INTO PESSOA (id_pessoa, cep, email, tipo_pessoa) VALUES 
(9, '13570-001', 'contato@agrocorp.com', 'J'), (10, '13571-100', 'adm@terraboa.com.br', 'J'),
(11, '13572-200', 'financeiro@coopsaojudas.com.br', 'J'), (12, '13573-300', 'compras@fazendasreunidas.com', 'J'),
(13, '13574-400', 'vendas@sementesol.com', 'J'), (14, '13575-500', 'rh@agrosul.com.br', 'J'),
(15, '13576-600', 'diretoria@graofino.com', 'J'), (16, '13577-700', 'suporte@ruraltech.com', 'J');
INSERT INTO PESSOA_JURIDICA (id_pessoa, cnpj, razao_social, nome_fantasia) VALUES
(9, '12.345.678/0001-99', 'Agro Corp S.A.', 'AgroCorp'), (10, '23.456.789/0001-12', 'Terra Boa Agronegocios Ltda', 'Terra Boa'),
(11, '34.567.890/0001-23', 'Cooperativa Sao Judas Tadeu', 'Coop Sao Judas'), (12, '45.678.901/0001-34', 'Fazendas Reunidas do Brasil S.A.', 'Fazendas Reunidas'),
(13, '56.789.012/0001-45', 'Semente do Sol Ltda', 'Semente Sol'), (14, '67.890.123/0001-56', 'Agropecuaria do Sul S.A.', 'AgroSul'),
(15, '78.901.234/0001-67', 'Grao Fino Armazens Gerais', 'Grao Fino'), (16, '89.012.345/0001-78', 'Rural Tech Solucoes Agricolas', 'RuralTech');

-- -------------------------------------------------------------------
-- Inserindo Imoveis Rurais
-- -------------------------------------------------------------------
INSERT INTO IMOVEL_RURAL (id_imovel_rural, nome_imovel, area_total_ha, cep) VALUES
(1, 'Fazenda Agua Limpa', 150.50, '13560-970'), (2, 'Sitio Bela Vista', 75.00, '13563-971'),
(3, 'Chacara Recanto Verde', 25.80, '13565-972'), (4, 'Fazenda Santa Rita', 210.00, '13568-100'),
(5, 'Sitio das Flores', 45.50, '13569-200'), (6, 'Chacara do Lago', 15.00, '13570-300'),
(7, 'Fazenda Boa Esperanca', 300.75, '13571-400'), (8, 'Sitio Santo Antonio', 88.00, '13572-500'),
(9, 'Chacara Sol Nascente', 12.20, '13573-600'), (10, 'Fazenda Monte Belo', 180.00, '13574-700'),
(11, 'Sitio Vovo Zeca', 55.00, '13561-110'), (12, 'Chacara Paraiso', 18.90, '13562-220'),
(13, 'Estancia Modelo', 500.00, '13563-330'), (14, 'Fazenda Paineiras', 250.25, '13564-440'),
(15, 'Sitio da Cachoeira', 62.00, '13565-550');

-- -------------------------------------------------------------------
-- Inserindo Propriedades
-- -------------------------------------------------------------------
INSERT INTO PROPRIEDADE (id_pessoa, id_imovel_rural, data_aquisicao, percentual_propriedade) VALUES
(1, 1, '2010-01-20', 100.00), (2, 2, '2015-06-10', 50.00), (1, 2, '2015-06-10', 50.00),
(3, 3, '2018-02-01', 100.00), (4, 4, '2005-08-15', 100.00), (5, 5, '2019-11-22', 100.00),
(6, 6, '2021-03-01', 100.00), (7, 7, '2000-01-01', 70.00), (8, 7, '2012-05-20', 30.00),
(9, 13, '2017-07-18', 100.00), (10, 14, '2016-09-30', 100.00), (11, 10, '2014-04-10', 100.00),
(1, 11, '2022-01-15', 100.00), (4, 12, '2023-02-20', 100.00), (12, 15, '2013-10-05', 100.00);

-- -------------------------------------------------------------------
-- Inserindo Catalogos (Agrotoxicos e Recursos Hidricos)
-- -------------------------------------------------------------------
INSERT INTO AGROTOXICO (nome_comercial, fabricante) VALUES
('Glifosato Nortox', 'Nortox'), ('Roundup Original', 'Monsanto'), ('2,4-D Amina 720', 'Dow AgroSciences'),
('Cletodim 240 EC', 'Syngenta'), ('Mancozebe 800 WP', 'UPL'), ('Imidacloprido 700 WG', 'Bayer'),
('Clorpirifos 480 EC', 'Corteva'), ('Tiametoxam 250 WG', 'Syngenta'), ('Fipronil 800 WG', 'BASF'),
('Azoxistrobina 250 SC', 'Adama'), ('Ciproconazol 500 SC', 'Nufarm'), ('Paraquat 200 SL', 'Helm'),
('Atrazina 500 SC', 'Albaugh'), ('Tebuconazol 200 EC', 'FMC'), ('Lambda-cialotrina 50 EC', 'CCAB');

INSERT INTO RECURSO_HIDRICO (nome_recurso, tipo_recurso) VALUES
('Corrego do Espraiado', 'Corrego'), ('Poco Profundo Sede', 'Poco Artesiano'), ('Rio Monjolinho', 'Rio'),
('Lagoa do Inferninho', 'Lagoa'), ('Nascente Santa Maria', 'Nascente'), ('Corrego da Agua Fria', 'Corrego'),
('Poco da Chacara', 'Poco Artesiano'), ('Rio Jacare-Guacu', 'Rio'), ('Lagoa Serena', 'Lagoa'),
('Nascente Bela Vista', 'Nascente'), ('Corrego do Ouro', 'Corrego'), ('Poco Comunitario', 'Poco Artesiano'),
('Rio Quilombo', 'Rio'), ('Açude Central', 'Lagoa'), ('Nascente da Mata', 'Nascente');

-- -------------------------------------------------------------------
-- Inserindo Pontos de Captacao de Agua
-- -------------------------------------------------------------------
INSERT INTO PONTO_CAPTACAO_AGUA (id_imovel_rural, id_recurso_hidrico, coordenadas_ponto, tipo_ponto) VALUES
(1, 1, '-22.01, -47.89', 'Bomba Flutuante'), (1, 2, '-22.02, -47.90', 'Bomba Submersa'),
(2, 6, '-22.03, -47.91', 'Barramento'), (4, 3, '-22.04, -47.92', 'Bomba Margem'),
(7, 8, '-22.05, -47.93', 'Canal de Derivacao'), (13, 13, '-22.06, -47.94', 'Bomba Central'),
(15, 5, '-22.07, -47.95', 'Roda d''agua'), (3, 7, '-22.08, -47.96', 'Poco Manual'),
(5, 10, '-22.09, -47.97', 'Captacao Direta'), (6, 9, '-22.10, -47.98', 'Bomba de Irrigacao'),
(8, 11, '-22.11, -47.99', 'Vala de Drenagem'), (9, 12, '-22.12, -48.00', 'Poco Artesiano'),
(10, 4, '-22.13, -48.01', 'Tomada de Agua'), (11, 14, '-22.14, -48.02', 'Bomba Sapo'),
(14, 15, '-22.15, -48.03', 'Captacao Nascente');

-- -------------------------------------------------------------------
-- Inserindo Producoes Agricolas
-- -------------------------------------------------------------------
INSERT INTO PRODUCAO_AGRICOLA (id_imovel_rural, cultura_plantada, area_cultivada_ha, data_plantio, safra, status_producao) VALUES
(1, 'Soja', 50.0, '2023-10-15', '2023/2024', 'Em Andamento'), (2, 'Milho', 20.0, '2023-11-01', '2023/2024', 'Em Andamento'),
(4, 'Cana-de-Açucar', 100.0, '2023-04-10', '2023/2024', 'Em Andamento'), (7, 'Laranja', 80.0, '2020-05-20', 'Anual', 'Em Andamento'),
(10, 'Cafe', 60.0, '2021-09-01', '2023/2024', 'Em Andamento'), (13, 'Eucalipto', 200.0, '2018-03-12', 'Rotativo', 'Em Andamento'),
(14, 'Algodao', 70.0, '2023-10-25', '2023/2024', 'Em Andamento'), (1, 'Trigo', 40.0, '2024-05-15', '2024', 'Planejada'),
(5, 'Feijao', 15.0, '2023-09-05', '2023', 'Colhida'), (8, 'Girassol', 30.0, '2023-08-20', '2023', 'Colhida'),
(11, 'Sorgo', 25.0, '2023-11-20', '2023/2024', 'Em Andamento'), (15, 'Mandioca', 10.0, '2023-02-18', '2023/2024', 'Em Andamento'),
(3, 'Hortalicas', 5.0, '2024-01-10', 'Mensal', 'Em Andamento'), (6, 'Tomate', 8.0, '2023-12-01', '2024', 'Em Andamento'),
(9, 'Abobora', 3.0, '2023-10-01', '2023', 'Colhida');

-- -------------------------------------------------------------------
-- Inserindo Aplicacao de Agrotoxicos
-- -------------------------------------------------------------------
INSERT INTO APLICACAO_AGROTOXICO (id_producao_agricola, id_agrotoxico, data_aplicacao, dose_utilizada, metodo_aplicacao) VALUES
(1, 1, '2023-11-25', '2 L/ha', 'Pulverizador Tratorizado'), (2, 13, '2023-12-05', '3 Kg/ha', 'Pulverizador Tratorizado'),
(3, 2, '2023-06-15', '2.5 L/ha', 'Pulverizador Tratorizado'), (4, 6, '2023-09-10', '500 mL/ha', 'Atomizador'),
(5, 4, '2023-10-01', '1 L/ha', 'Pulverizador Costal'), (7, 7, '2023-07-20', '1.5 L/ha', 'Atomizador'),
(10, 10, '2023-11-30', '800 g/ha', 'Pulverizador Tratorizado'), (11, 1, '2023-12-15', '1.8 L/ha', 'Pulverizador Tratorizado'),
(14, 8, '2023-12-20', '300 g/ha', 'Pulverizador Tratorizado'), (1, 5, '2023-12-01', '2 Kg/ha', 'Pulverizador Tratorizado'),
(2, 9, '2024-01-05', '100 g/ha', 'Tratamento de Semente'), (3, 12, '2023-07-10', '1 L/ha', 'Aplicacao Aerea'),
(4, 11, '2023-10-05', '700 mL/ha', 'Atomizador'), (7, 15, '2023-08-15', '400 mL/ha', 'Atomizador'),
(13, 3, '2024-02-01', '1.2 L/ha', 'Pulverizador Costal');

-- -------------------------------------------------------------------
-- Inserindo Uso de Recurso Hidrico
-- -------------------------------------------------------------------
INSERT INTO USO_RECURSO_HIDRICO (id_producao_agricola, id_ponto_captacao, data_inicio_uso, volume_agua_captado_m3, tipo_irrigacao_usado) VALUES
(2, 1, '2023-12-01', 5000, 'Aspersao'), (3, 4, '2023-05-01', 15000, 'Gotejamento'),
(4, 5, '2023-06-01', 12000, 'Microaspersao'), (5, 9, '2023-09-20', 2000, 'Gotejamento'),
(7, 5, '2023-07-01', 25000, 'Microaspersao'), (8, 11, '2023-09-10', 3000, 'Pivô Central'),
(10, 13, '2023-10-01', 8000, 'Gotejamento'), (11, 2, '2023-12-10', 4000, 'Aspersao'),
(12, 15, '2023-03-15', 1500, 'Gotejamento'), (13, 8, '2024-01-20', 1000, 'Gotejamento'),
(14, 6, '2023-11-15', 9000, 'Pivô Central'), (15, 7, '2023-04-01', 1200, 'Sulcos'),
(1, 1, '2023-11-10', 6000, 'Pivô Central'), (6, 10, '2024-01-05', 900, 'Gotejamento'),
(9, 12, '2023-10-15', 500, 'Gotejamento');

-- -------------------------------------------------------------------
-- Inserindo Producao Pecuaria
-- -------------------------------------------------------------------
INSERT INTO PRODUCAO_PECUARIA (id_imovel_rural, tipo_criacao, qtd_animais, raca, finalidade) VALUES
(1, 'Bovino de Corte', 200, 'Nelore', 'Carne'), (4, 'Bovino de Leite', 80, 'Holandesa', 'Leite'),
(7, 'Galinha Poedeira', 5000, 'Hy-Line', 'Ovos'), (13, 'Suino', 1000, 'Landrace', 'Carne'),
(2, 'Ovino', 150, 'Santa Ines', 'Carne e Lã'), (5, 'Caprino', 100, 'Boer', 'Carne e Leite'),
(8, 'Frango de Corte', 10000, 'Cobb', 'Carne'), (10, 'Equino', 20, 'Manga-larga', 'Trabalho e Lazer'),
(14, 'Apicultura', 50, 'Apis mellifera', 'Mel e Polinização'), (15, 'Piscicultura', 3000, 'Tilapia', 'Carne'),
(3, 'Codornas', 2000, 'Japonesa', 'Ovos e Carne'), (6, 'Gado Misto', 50, 'Girolando', 'Carne e Leite'),
(9, 'Coelhos', 300, 'Nova Zelandia', 'Carne'), (11, 'Búfalos', 40, 'Murrah', 'Leite e Carne'),
(12, 'Avestruz', 30, 'Pescoço Azul', 'Carne e Couro');


-- ===================================================================
-- SEÇÃO 4: CRIAÇÃO DE STORED PROCEDURES
-- ===================================================================

-- 1. Procedure para adicionar um novo proprietario a um imovel existente.
CREATE OR REPLACE PROCEDURE sp_AdicionarProprietario(
    p_id_pessoa INTEGER,
    p_id_imovel_rural INTEGER,
    p_data_aquisicao DATE,
    p_percentual NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PESSOA WHERE id_pessoa = p_id_pessoa) THEN
        RAISE EXCEPTION 'Pessoa com ID % nao encontrada.', p_id_pessoa;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM IMOVEL_RURAL WHERE id_imovel_rural = p_id_imovel_rural) THEN
        RAISE EXCEPTION 'Imovel Rural com ID % nao encontrado.', p_id_imovel_rural;
    END IF;

    INSERT INTO PROPRIEDADE (id_pessoa, id_imovel_rural, data_aquisicao, percentual_propriedade)
    VALUES (p_id_pessoa, p_id_imovel_rural, p_data_aquisicao, p_percentual);
    
    RAISE NOTICE 'Proprietario adicionado com sucesso ao imovel.';
END;
$$;

-- 2. Procedure para arquivar producoes agricolas antigas.
CREATE OR REPLACE PROCEDURE sp_ArquivarProducoesAntigas(
    p_anos_antiguidade INTEGER DEFAULT 2
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_data_limite DATE;
    v_contagem INTEGER;
BEGIN
    v_data_limite := CURRENT_DATE - (p_anos_antiguidade * INTERVAL '1 year');
    
    UPDATE PRODUCAO_AGRICOLA
    SET status_producao = 'Colhida'
    WHERE status_producao = 'Em Andamento' AND data_colheita_prevista < v_data_limite;
    
    GET DIAGNOSTICS v_contagem = ROW_COUNT;
    RAISE NOTICE '% producoes antigas foram atualizadas.', v_contagem;
END;
$$;

-- 3. Procedure para atualizar o e-mail e telefone de uma pessoa.
CREATE OR REPLACE PROCEDURE sp_AtualizarContatoPessoa(
    p_id_pessoa INTEGER,
    p_novo_email VARCHAR,
    p_novo_telefone VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE PESSOA
    SET email = p_novo_email,
        telefone = p_novo_telefone
    WHERE id_pessoa = p_id_pessoa;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pessoa com ID % nao encontrada.', p_id_pessoa;
    END IF;

    RAISE NOTICE 'Contato da pessoa % atualizado.', p_id_pessoa;
END;
$$;


-- ===================================================================
-- SEÇÃO 5: CRIAÇÃO DE FUNCTIONS
-- ===================================================================

-- 1. Funcao para calcular a area total cultivada em um imovel rural.
CREATE OR REPLACE FUNCTION fn_CalcularAreaCultivadaImovel(
    p_id_imovel_rural INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(area_cultivada_ha), 0)
    INTO v_area_total
    FROM PRODUCAO_AGRICOLA
    WHERE id_imovel_rural = p_id_imovel_rural
      AND status_producao IN ('Em Andamento', 'Planejada');
      
    RETURN v_area_total;
END;
$$;

-- 2. Funcao que retorna os detalhes de um proprietario (Pessoa Fisica ou Juridica).
CREATE OR REPLACE FUNCTION fn_ObterDetalhesPessoa(
    p_id_pessoa INTEGER
)
RETURNS TABLE (
    id INTEGER,
    tipo VARCHAR,
    documento VARCHAR,
    nome_razao_social VARCHAR,
    email VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id_pessoa,
        CASE p.tipo_pessoa WHEN 'F' THEN 'Fisica' ELSE 'Juridica' END,
        COALESCE(pf.cpf, pj.cnpj),
        COALESCE(pf.nome_completo, pj.razao_social),
        p.email
    FROM PESSOA p
    LEFT JOIN PESSOA_FISICA pf ON p.id_pessoa = pf.id_pessoa AND p.tipo_pessoa = 'F'
    LEFT JOIN PESSOA_JURIDICA pj ON p.id_pessoa = pj.id_pessoa AND p.tipo_pessoa = 'J'
    WHERE p.id_pessoa = p_id_pessoa;
END;
$$;

-- 3. Funcao para contar o numero de aplicacoes de um agrotoxico especifico.
CREATE OR REPLACE FUNCTION fn_ContarAplicacoesAgrotoxico(
    p_id_agrotoxico INTEGER,
    p_data_inicio DATE,
    p_data_fim DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_contagem INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_contagem
    FROM APLICACAO_AGROTOXICO
    WHERE id_agrotoxico = p_id_agrotoxico
      AND data_aplicacao BETWEEN p_data_inicio AND p_data_fim;
      
    RETURN v_contagem;
END;
$$;


-- ===================================================================
-- SEÇÃO 6: CRIAÇÃO DE TRIGGERS
-- ===================================================================

-- 1. Trigger para atualizar automaticamente a data de modificacao de um imovel rural.
CREATE OR REPLACE FUNCTION fn_atualizar_data_modificacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.data_modificacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_imovel_modificacao
BEFORE UPDATE ON IMOVEL_RURAL
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_data_modificacao();


-- 2. Trigger para impedir a exclusao de um Recurso Hidrico se ele estiver em uso.
CREATE OR REPLACE FUNCTION fn_check_recurso_hidrico_em_uso()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM PONTO_CAPTACAO_AGUA WHERE id_recurso_hidrico = OLD.id_recurso_hidrico) THEN
        RAISE EXCEPTION 'Nao eh possivel excluir o Recurso Hidrico ID % pois ele esta associado a um ou mais Pontos de Captacao.', OLD.id_recurso_hidrico;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_prevent_delete_recurso_hidrico
BEFORE DELETE ON RECURSO_HIDRICO
FOR EACH ROW
EXECUTE FUNCTION fn_check_recurso_hidrico_em_uso();


-- 3. Trigger para auditar mudancas na tabela PROPRIEDADE.
CREATE OR REPLACE FUNCTION fn_log_propriedade_mudancas()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO LOG_PROPRIEDADE (operacao, usuario_db, timestamp_log, id_propriedade_novo, id_pessoa_novo, id_imovel_novo, percentual_novo)
        VALUES ('I', session_user, NOW(), NEW.id_propriedade, NEW.id_pessoa, NEW.id_imovel_rural, NEW.percentual_propriedade);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO LOG_PROPRIEDADE (operacao, usuario_db, timestamp_log, id_propriedade_antigo, id_pessoa_antigo, id_imovel_antigo, percentual_antigo, id_propriedade_novo, id_pessoa_novo, id_imovel_novo, percentual_novo)
        VALUES ('U', session_user, NOW(), OLD.id_propriedade, OLD.id_pessoa, OLD.id_imovel_rural, OLD.percentual_propriedade, NEW.id_propriedade, NEW.id_pessoa, NEW.id_imovel_rural, NEW.percentual_propriedade);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO LOG_PROPRIEDADE (operacao, usuario_db, timestamp_log, id_propriedade_antigo, id_pessoa_antigo, id_imovel_antigo, percentual_antigo)
        VALUES ('D', session_user, NOW(), OLD.id_propriedade, OLD.id_pessoa, OLD.id_imovel_rural, OLD.percentual_propriedade);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_audit_propriedade
AFTER INSERT OR UPDATE OR DELETE ON PROPRIEDADE
FOR EACH ROW
EXECUTE FUNCTION fn_log_propriedade_mudancas();

-- =============================================================================
-- | FIM DO SCRIPT                                                             |
-- =============================================================================