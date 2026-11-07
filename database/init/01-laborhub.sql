CREATE DATABASE  IF NOT EXISTS `FluuterLaborHub` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `FluuterLaborHub`;
-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: FluuterLaborHub
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.24.04.4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `avaliacao`
--

DROP TABLE IF EXISTS `avaliacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `avaliacao` (
  `avaliacao_id` int NOT NULL AUTO_INCREMENT,
  `avaliacao_assunto` varchar(120) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `avaliacao_descricao` text COLLATE utf8mb4_general_ci,
  `avaliacao_resposta` text COLLATE utf8mb4_general_ci,
  `avaliacao_notas` int DEFAULT NULL,
  `avaliacao_data` date DEFAULT NULL,
  `avaliador_usuarios_id` int DEFAULT NULL,
  `avaliado_usuarios_id` int DEFAULT NULL,
  `avaliacao_solicitacao_id` int DEFAULT NULL,
  PRIMARY KEY (`avaliacao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `avaliacao`
--

LOCK TABLES `avaliacao` WRITE;
/*!40000 ALTER TABLE `avaliacao` DISABLE KEYS */;
/*!40000 ALTER TABLE `avaliacao` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `endereco`
--

DROP TABLE IF EXISTS `endereco`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `endereco` (
  `endereco_id` int NOT NULL AUTO_INCREMENT,
  `endereco_nome` varchar(30) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_rua` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_bairro` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_cep` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_complemento` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_numero` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_descricao` text COLLATE utf8mb4_general_ci,
  `endereco_cidade` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_uf` varchar(2) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `endereco_usuarios_id` int DEFAULT NULL,
  PRIMARY KEY (`endereco_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `endereco`
--

LOCK TABLES `endereco` WRITE;
/*!40000 ALTER TABLE `endereco` DISABLE KEYS */;
/*!40000 ALTER TABLE `endereco` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pessoaFisica`
--

DROP TABLE IF EXISTS `pessoaFisica`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pessoaFisica` (
  `pf_id` int NOT NULL AUTO_INCREMENT,
  `pf_nome` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pf_sobrenome` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pf_dataNascimento` date DEFAULT NULL,
  `pf_genero` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pf_cpf` varchar(15) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pf_tipo` varchar(15) COLLATE utf8mb4_general_ci NOT NULL,
  `pf_usuarios_id` int DEFAULT NULL,
  PRIMARY KEY (`pf_id`),
  UNIQUE KEY `pf_cpf` (`pf_cpf`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pessoaFisica`
--

LOCK TABLES `pessoaFisica` WRITE;
/*!40000 ALTER TABLE `pessoaFisica` DISABLE KEYS */;
/*!40000 ALTER TABLE `pessoaFisica` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pessoaJuridica`
--

DROP TABLE IF EXISTS `pessoaJuridica`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pessoaJuridica` (
  `pj_id` int NOT NULL AUTO_INCREMENT,
  `pj_razaoSocial` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pj_nomeFantasia` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pj_dataFundacao` date DEFAULT NULL,
  `pj_cnpj` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pj_tipo` varchar(15) COLLATE utf8mb4_general_ci NOT NULL,
  `pj_usuarios_id` int DEFAULT NULL,
  PRIMARY KEY (`pj_id`),
  UNIQUE KEY `pj_cnpj` (`pj_cnpj`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pessoaJuridica`
--

LOCK TABLES `pessoaJuridica` WRITE;
/*!40000 ALTER TABLE `pessoaJuridica` DISABLE KEYS */;
/*!40000 ALTER TABLE `pessoaJuridica` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `servicos`
--

DROP TABLE IF EXISTS `servicos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `servicos` (
  `servicos_id` int NOT NULL AUTO_INCREMENT,
  `servicos_nome` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `servicos_data` varchar(25) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `servicos_valor` decimal(9,2) DEFAULT NULL,
  `servicos_tipo_cobranca` text COLLATE utf8mb4_general_ci,
  `servicos_nivel_experiencia` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `servicos_descricao` text COLLATE utf8mb4_general_ci,
  `servicos_usuarios_id` int DEFAULT NULL,
  PRIMARY KEY (`servicos_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `servicos`
--

LOCK TABLES `servicos` WRITE;
/*!40000 ALTER TABLE `servicos` DISABLE KEYS */;
/*!40000 ALTER TABLE `servicos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `solicitacao`
--

DROP TABLE IF EXISTS `solicitacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solicitacao` (
  `solicitacao_id` int NOT NULL AUTO_INCREMENT,
  `solicitacao_data` date DEFAULT NULL,
  `solicitacao_data_atual` date DEFAULT NULL,
  `solicitacao_conclusao` date DEFAULT NULL,
  `solicitacao_quantidade` int NOT NULL,
  `solicitacao_observacao` text COLLATE utf8mb4_general_ci,
  `solicitacao_criada_em` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `solicitacao_atualizada_em` timestamp NULL DEFAULT NULL,
  `solicitacao_deletada_em` timestamp NULL DEFAULT NULL,
  `solicitacao_status` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `solicitacao_status_profissional` varchar(30) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `solicitacao_motivo` varchar(250) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `solicitacao_endereco_id` int DEFAULT NULL,
  `solicitacao_usuarios_id` int DEFAULT NULL,
  PRIMARY KEY (`solicitacao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitacao`
--

LOCK TABLES `solicitacao` WRITE;
/*!40000 ALTER TABLE `solicitacao` DISABLE KEYS */;
/*!40000 ALTER TABLE `solicitacao` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `solicitacaoServico`
--

DROP TABLE IF EXISTS `solicitacaoServico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solicitacaoServico` (
  `solicitacaoServico_id` int NOT NULL AUTO_INCREMENT,
  `solicitacaoServico_servicos_id` int DEFAULT NULL,
  `solicitacaoServico_solicitacao_id` int DEFAULT NULL,
  PRIMARY KEY (`solicitacaoServico_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitacaoServico`
--

LOCK TABLES `solicitacaoServico` WRITE;
/*!40000 ALTER TABLE `solicitacaoServico` DISABLE KEYS */;
/*!40000 ALTER TABLE `solicitacaoServico` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `usuarios_id` int NOT NULL AUTO_INCREMENT,
  `usuarios_email` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usuarios_imagem` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usuarios_telefone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usuarios_senha_hash` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usuarios_ativo` tinyint(1) DEFAULT NULL,
  `usuarios_is_admin` tinyint(1) DEFAULT NULL,
  `usuarios_reset_hash` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usuarios_expira_em` timestamp NULL DEFAULT NULL,
  `usuarios_ativacao_hash` timestamp NULL DEFAULT NULL,
  `usuarios_criado_em` timestamp NULL DEFAULT NULL,
  `usuarios_atualizado_em` timestamp NULL DEFAULT NULL,
  `usuarios_deletado_em` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`usuarios_id`),
  UNIQUE KEY `usuarios_email` (`usuarios_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-07 14:37:14
