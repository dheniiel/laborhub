-- Garante no banco que cada serviço (solicitação) recebe no máximo uma avaliação.
USE `FluuterLaborHub`;

ALTER TABLE `avaliacao`
  ADD UNIQUE KEY `avaliacao_solicitacao_id` (`avaliacao_solicitacao_id`),
  ADD KEY `avaliado_usuarios_id` (`avaliado_usuarios_id`);