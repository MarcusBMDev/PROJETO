const mysql = require('mysql2');

// Configuração do Pool de Conexões (Garante reconexão automática e estabilidade)
const pool = mysql.createPool({
    host: '127.0.0.1', 
    user: 'root',
    password: '',
    database: 'neurochat_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
});

console.log('✅ Pool de Conexões da Ouvidoria configurado.');

module.exports = pool;
