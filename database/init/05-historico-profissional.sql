-- Ocultação individual do histórico do profissional.
USE `FluuterLaborHub`;

CREATE TABLE IF NOT EXISTS historico_profissional_oculto (
  profissional_id INT NOT NULL,
  solicitacao_id INT NOT NULL,
  ocultado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (profissional_id, solicitacao_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
