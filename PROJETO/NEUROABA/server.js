const express = require('express');
const cors = require('cors');
const path = require('path'); // <- Nova ferramenta para lidar com pastas
const { dbPacientes, dbUsuarios } = require('./src/config/database');

const app = express();
const porta = 3012;

app.use(cors());
app.use(express.json());

// 1. CONFIGURAÇÃO DO FRONTEND (Telas)
// Dizemos ao Node.js que a pasta 'src/views' contém arquivos públicos (HTML, JS)
app.use(express.static(path.join(__dirname, 'src/views')));

// 2. ROTAS DO BACKEND (APIs)
const rotasApi = require('./src/routes/rotas');
app.use('/api', rotasApi); 

// 3. ROTA PRINCIPAL (O que acontece ao acessar localhost:3012)
app.get('/', (req, res) => {
    // Agora, em vez de mandar um texto, ele manda o usuário direto para a tela de login
    res.redirect('/login.html');
});

// (Opcional) Mantemos a rota de teste de banco se você quiser consultar depois
app.get('/api/testar-bancos', async (req, res) => {
    try {
        const [pacientes] = await dbPacientes.query('SELECT id, nome FROM pacientes LIMIT 3');
        const [usuarios] = await dbUsuarios.query('SELECT id, username, department FROM users LIMIT 3');
        res.json({ mensagem: "Conexão com bancos externos feita com sucesso!", pacientes, usuarios });
    } catch (erro) {
        res.status(500).json({ erro: "Falha ao conectar nos bancos." });
    }
});

app.listen(porta, () => {
    console.log(`🚀 Servidor NeuroABA iniciado em http://localhost:${porta}`);
});