-- ============================================================
--  NEUROGESTÃO - Atualização de Especialidades
--  Execute este arquivo no banco: agendamentos_clinica_dev
-- ============================================================

-- PASSO 1: Limpar e repovoar a tabela de especialidades (catálogo)
DELETE FROM especialidades;

INSERT INTO especialidades (nome, created_at, updated_at) VALUES
  ('ABA',                        NOW(), NOW()),
  ('ATENDENTE TERAPÊUTICO',      NOW(), NOW()),
  ('AVALIAÇÃO NEUROPSICOLÓGICA', NOW(), NOW()),
  ('ESTIMULAÇÃO COGNITIVA',      NOW(), NOW()),
  ('FONOAUDIOLOGIA',             NOW(), NOW()),
  ('MUSICOTERAPIA',              NOW(), NOW()),
  ('NEUROPSICOPEDAGOGIA',        NOW(), NOW()),
  ('PSICOMOTRICIDADE',           NOW(), NOW()),
  ('PSICOTERAPIA',               NOW(), NOW()),
  ('TERAPIA OCUPACIONAL',        NOW(), NOW());

-- ============================================================
-- PASSO 2: Atualizar especialidade de cada profissional
-- ============================================================

UPDATE profissionais SET especialidade = 'NEUROPSICOPEDAGOGIA'        WHERE UPPER(TRIM(nome)) LIKE '%AMANDA%';
UPDATE profissionais SET especialidade = 'PSICOMOTRICIDADE'           WHERE UPPER(TRIM(nome)) LIKE '%ANA CAROLINE%';
UPDATE profissionais SET especialidade = 'AVALIAÇÃO NEUROPSICOLÓGICA' WHERE UPPER(TRIM(nome)) LIKE '%ANA PAULA%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%ARMANDO%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%CRISLENE%';
UPDATE profissionais SET especialidade = 'FONOAUDIOLOGIA'             WHERE UPPER(TRIM(nome)) LIKE '%DAYANE%';
UPDATE profissionais SET especialidade = 'MUSICOTERAPIA'              WHERE UPPER(TRIM(nome)) LIKE '%ELDA%';
UPDATE profissionais SET especialidade = 'NEUROPSICOPEDAGOGIA'        WHERE UPPER(TRIM(nome)) LIKE '%ELIANE%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%ELIENE%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%ERICA%';
UPDATE profissionais SET especialidade = 'NEUROPSICOPEDAGOGIA'        WHERE UPPER(TRIM(nome)) LIKE '%EUCILENE%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%FLAVIA%';
UPDATE profissionais SET especialidade = 'TERAPIA OCUPACIONAL'        WHERE UPPER(TRIM(nome)) LIKE '%FRANCISCO%';
UPDATE profissionais SET especialidade = 'ABA'                        WHERE UPPER(TRIM(nome)) LIKE '%GABRIEL%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%GEOVANA%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%ISABELLA%';
UPDATE profissionais SET especialidade = 'TERAPIA OCUPACIONAL'        WHERE UPPER(TRIM(nome)) LIKE '%ISABELLY%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%JAQUELINE%';
UPDATE profissionais SET especialidade = 'FONOAUDIOLOGIA'             WHERE UPPER(TRIM(nome)) LIKE '%JAYDE%';
UPDATE profissionais SET especialidade = 'ESTIMULAÇÃO COGNITIVA'      WHERE UPPER(TRIM(nome)) LIKE '%JESSICA%';
UPDATE profissionais SET especialidade = 'AVALIAÇÃO NEUROPSICOLÓGICA' WHERE UPPER(TRIM(nome)) LIKE '%JOYCE%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%JULYANE%';
UPDATE profissionais SET especialidade = 'FONOAUDIOLOGIA'             WHERE UPPER(TRIM(nome)) LIKE '%KARINE%';
UPDATE profissionais SET especialidade = 'NEUROPSICOPEDAGOGIA'        WHERE UPPER(TRIM(nome)) LIKE '%KELLEN%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%LARISSA%';
UPDATE profissionais SET especialidade = 'ABA'                        WHERE UPPER(TRIM(nome)) LIKE '%LAURA%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%LEIDIANE%';
UPDATE profissionais SET especialidade = 'FONOAUDIOLOGIA'             WHERE UPPER(TRIM(nome)) LIKE '%LIDIANE%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%LIVIA%';
UPDATE profissionais SET especialidade = 'TERAPIA OCUPACIONAL'        WHERE UPPER(TRIM(nome)) LIKE '%LUIZA%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%MARCELLA%';
UPDATE profissionais SET especialidade = 'PSICOMOTRICIDADE'           WHERE UPPER(TRIM(nome)) LIKE '%MARIA EDUARDA%';
UPDATE profissionais SET especialidade = 'TERAPIA OCUPACIONAL'        WHERE UPPER(TRIM(nome)) LIKE '%MARINA%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%MARKUS%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%MAYARA%';
UPDATE profissionais SET especialidade = 'ABA'                        WHERE UPPER(TRIM(nome)) LIKE '%MONICA%';
UPDATE profissionais SET especialidade = 'ABA'                        WHERE UPPER(TRIM(nome)) LIKE '%NAYALIA%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%NATHALI%';
UPDATE profissionais SET especialidade = 'NEUROPSICOPEDAGOGIA'        WHERE UPPER(TRIM(nome)) LIKE '%POLLYANA%';
UPDATE profissionais SET especialidade = 'PSICOTERAPIA'               WHERE UPPER(TRIM(nome)) LIKE '%RAAB%';
UPDATE profissionais SET especialidade = 'AVALIAÇÃO NEUROPSICOLÓGICA' WHERE UPPER(TRIM(nome)) LIKE '%RAISSA%';
UPDATE profissionais SET especialidade = 'TERAPIA OCUPACIONAL'        WHERE UPPER(TRIM(nome)) LIKE '%RAPHAELA%';
UPDATE profissionais SET especialidade = 'FONOAUDIOLOGIA'             WHERE UPPER(TRIM(nome)) LIKE '%VICTORIA LUIZA%';
UPDATE profissionais SET especialidade = 'ATENDENTE TERAPÊUTICO'      WHERE UPPER(TRIM(nome)) LIKE '%VITORIA%';

-- ============================================================
-- PASSO 3: Verificar resultado (execute separadamente)
-- ============================================================
-- SELECT nome, especialidade FROM profissionais ORDER BY nome;
-- SELECT nome FROM especialidades ORDER BY nome;
