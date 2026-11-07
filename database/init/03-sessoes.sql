-- Sessões de login da API. Guarda somente o HMAC do token; o token em si fica apenas no aparelho.
USE `FluuterLaborHub`;

CREATE TABLE IF NOT EXISTS `sessoes` (
  `sessoes_id` int NOT NULL AUTO_INCREMENT,
  `sessoes_token_hash` char(64) NOT NULL,
  `sessoes_usuarios_id` int NOT NULL,
  `sessoes_criada_em` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sessoes_expira_em` timestamp NOT NULL,
  PRIMARY KEY (`sessoes_id`),
  UNIQUE KEY `sessoes_token_hash` (`sessoes_token_hash`),
  KEY `sessoes_usuarios_id` (`sessoes_usuarios_id`),
  KEY `sessoes_expira_em` (`sessoes_expira_em`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
