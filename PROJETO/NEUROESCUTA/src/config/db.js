const mysql = require('mysql2');
require('dotenv').config();

// Configuração do Pool de Conexões (Garante reconexão automática e estabilidade)
const pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1', 
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'neurochat_db',
    port: process.env.DB_PORT || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
});

console.log('✅ Pool de Conexões da Ouvidoria configurado.');

module.exports = pool;
