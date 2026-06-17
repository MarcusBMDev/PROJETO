const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Inicializa o App
const app = express();

// Middlewares Globais
app.use(express.json());
app.use(cors());
app.use(express.static(path.join(__dirname, 'public')));

// Importa as Rotas da API
const apiRoutes = require('./src/routes/api');
app.use('/api', apiRoutes);

// Rota Raiz (Front-end)
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'solicitar.html'));
});

// Inicializa o Servidor
const PORT = process.env.PORT || 3005;
app.listen(PORT, () => console.log(`🚀 NeuroMarketing rodando na porta ${PORT}`));