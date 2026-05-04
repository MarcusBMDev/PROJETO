const express = require('express');
const router = express.Router();

// Importa o nosso Garçom (Controller)
const SessaoController = require('../controllers/SessaoController');
const AuthController = require('../controllers/AuthController');

// Define as rotas (URLs) do nosso sistema
router.get('/dados-iniciais', SessaoController.listarDadosIniciais);
router.post('/salvar-sessao', SessaoController.salvarSessao);
router.get('/relatorios/:paciente_id', SessaoController.buscarRelatorioPaciente);
router.get('/historico', SessaoController.listarHistorico);

// 2. Adicione a rota de login:
router.post('/login', AuthController.login);

module.exports = router;