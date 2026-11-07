-- Tabela auxiliar da API: limites de tentativas (login, cadastro e recuperação de senha).
-- Não altera as tabelas de 01-laborhub.sql. A chave é um HMAC; não guarda emails nem IPs em texto.
USE `FluuterLaborHub`;

CREATE TABLE IF NOT EXISTS `limites` (
  `limites_chave` char(64) NOT NULL,
  `limites_inicio` int NOT NULL,
  `limites_total` int NOT NULL,
  PRIMARY KEY (`limites_chave`),
  KEY `limites_inicio` (`limites_inicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
