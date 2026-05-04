CREATE DATABASE IF NOT EXISTS agendamentos_clinica_dev DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agendamentos_clinica_dev;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `active_storage_attachments`;
DROP TABLE IF EXISTS `active_storage_blobs`;
DROP TABLE IF EXISTS `active_storage_variant_records`;
DROP TABLE IF EXISTS `agendamentos`;
DROP TABLE IF EXISTS `convenios`;
DROP TABLE IF EXISTS `especialidades`;
DROP TABLE IF EXISTS `lista_espera`;
DROP TABLE IF EXISTS `pacientes`;
DROP TABLE IF EXISTS `profissionais`;
DROP TABLE IF EXISTS `transferencias`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `schema_migrations`;
DROP TABLE IF EXISTS `ar_internal_metadata`;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `convenios` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `ativo` tinyint(1) DEFAULT NULL,
  `especialidades_atendidas` text DEFAULT NULL,
  `exigencias` text DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `especialidades` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_especialidades_on_nome` (`nome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `pacientes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `age` int(11) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `convenio_id` int(11) DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `planned_specialties` text DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `weekly_frequency` int(11) DEFAULT NULL,
  `deleted_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_pacientes_on_nome` (`nome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `profissionais` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `ativo` tinyint(1) DEFAULT '1',
  `especialidade` varchar(255) DEFAULT NULL,
  `max_age` int(11) DEFAULT NULL,
  `min_age` int(11) DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `lista_espera` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `age` int(11) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `especialidade` varchar(255) DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `observacao` text DEFAULT NULL,
  `paciente_id` bigint(20) DEFAULT NULL,
  `planned_specialties` text DEFAULT NULL,
  `status` varchar(255) DEFAULT 'aguardando',
  `telefone` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_lista_espera_on_paciente_id` (`paciente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `agendamentos` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `bloqueado_por` varchar(255) DEFAULT NULL,
  `bloqueado_por_id` int(11) DEFAULT NULL,
  `convenio_id` bigint(20) DEFAULT NULL,
  `dia_semana` varchar(255) DEFAULT NULL,
  `encaixe` tinyint(1) DEFAULT '0',
  `horario` varchar(255) DEFAULT NULL,
  `lista_espera_id` bigint(20) DEFAULT NULL,
  `motivo_bloqueio` text DEFAULT NULL,
  `observacoes` text DEFAULT NULL,
  `paciente_id` bigint(20) DEFAULT NULL,
  `profissional_id` bigint(20) NOT NULL,
  `status` varchar(255) DEFAULT 'confirmado',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_agendamentos_on_convenio_id` (`convenio_id`),
  KEY `index_agendamentos_on_lista_espera_id` (`lista_espera_id`),
  KEY `index_agendamentos_on_paciente_id` (`paciente_id`),
  KEY `idx_agendamentos_busca` (`profissional_id`, `dia_semana`, `horario`),
  KEY `index_agendamentos_on_profissional_id` (`profissional_id`),
  KEY `index_agendamentos_on_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `transferencias` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `agendamento_ids` text DEFAULT NULL,
  `agendamento_origem_id` bigint(20) DEFAULT NULL,
  `de_profissional_id` bigint(20) DEFAULT NULL,
  `encaixe` tinyint(1) DEFAULT NULL,
  `motivo` text DEFAULT NULL,
  `novo_dia_semana` varchar(255) DEFAULT NULL,
  `novo_horario` varchar(255) DEFAULT NULL,
  `paciente_id` bigint(20) NOT NULL,
  `para_profissional_id` bigint(20) DEFAULT NULL,
  `solicitante` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT 'pendente',
  `tipo` int(11) DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_transferencias_on_de_profissional_id` (`de_profissional_id`),
  KEY `index_transferencias_on_paciente_id` (`paciente_id`),
  KEY `index_transferencias_on_para_profissional_id` (`para_profissional_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `department` varchar(255) DEFAULT NULL,
  `is_super_admin` tinyint(1) DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `active_storage_blobs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `byte_size` bigint(20) NOT NULL,
  `checksum` varchar(255) DEFAULT NULL,
  `content_type` varchar(255) DEFAULT NULL,
  `filename` varchar(255) NOT NULL,
  `key` varchar(255) NOT NULL,
  `metadata` text DEFAULT NULL,
  `service_name` varchar(255) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_blobs_on_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `active_storage_attachments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `blob_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `record_id` bigint(20) NOT NULL,
  `record_type` varchar(255) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_attachments_uniqueness` (`record_type`,`record_id`,`name`,`blob_id`),
  KEY `index_active_storage_attachments_on_blob_id` (`blob_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `active_storage_variant_records` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `blob_id` bigint(20) NOT NULL,
  `variation_digest` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_variant_records_uniqueness` (`blob_id`,`variation_digest`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Constraints
ALTER TABLE `active_storage_attachments`
  ADD CONSTRAINT `fk_rails_c3b3935057` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`);

ALTER TABLE `active_storage_variant_records`
  ADD CONSTRAINT `fk_rails_993965df05` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`);

ALTER TABLE `agendamentos`
  ADD CONSTRAINT `fk_agendamentos_convenios` FOREIGN KEY (`convenio_id`) REFERENCES `convenios` (`id`),
  ADD CONSTRAINT `fk_agendamentos_pacientes` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`),
  ADD CONSTRAINT `fk_agendamentos_profissionais` FOREIGN KEY (`profissional_id`) REFERENCES `profissionais` (`id`);

ALTER TABLE `transferencias`
  ADD CONSTRAINT `fk_transferencias_pacientes` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`),
  ADD CONSTRAINT `fk_transferencias_de_profissional` FOREIGN KEY (`de_profissional_id`) REFERENCES `profissionais` (`id`),
  ADD CONSTRAINT `fk_transferencias_para_profissional` FOREIGN KEY (`para_profissional_id`) REFERENCES `profissionais` (`id`);

-- Seed required schema migrations versions
INSERT IGNORE INTO `schema_migrations` (`version`) VALUES 
('20260310145344'),
('20260310145347'),
('20260310145351'),
('20260310145354'),
('20260310200948'),
('20260316210727'),
('20260317191715'),
('20260317194230'),
('20260318174627'),
('20260318174641'),
('20260318191946'),
('20260320134000'),
('20260320143000'),
('20260320173633'),
('20260320192130'),
('20260320202448'),
('20260320203329'),
('20260320203958'),
('20260324115118'),
('20260324115219'),
('20260401143600'),
('20260402121728'),
('20260409170924'),
('20260409192942');

SET FOREIGN_KEY_CHECKS = 1;
