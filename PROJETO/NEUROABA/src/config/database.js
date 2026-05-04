// Importamos a biblioteca mysql2 preparada para trabalhar de forma assíncrona (Promises)
const mysql = require('mysql2/promise');

// 1. Conexão Principal (Onde vamos salvar os dados do NeuroABA futuramente)
// Vamos chamar esse banco de 'neuroaba_db' (você precisará criá-lo vazio no phpMyAdmin depois)
const dbPrincipal = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'neuroaba_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 2. Conexão Externa 1: Banco de Pacientes
const dbPacientes = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'agendamentos_clinica_dev', // Nome exato conforme seu print
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 3. Conexão Externa 2: Banco de Usuários (ATs/Terapeutas)
const dbUsuarios = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'neurochat_db', // Nome exato conforme seu print
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Exportamos as três conexões para usarmos no restante do sistema
module.exports = {
    dbPrincipal,
    dbPacientes,
    dbUsuarios
};