const mysql = require('mysql2');

const pool = mysql.createPool({
    host: '127.0.0.1',
    user: 'root',
    password: '', // Coloca a tua senha do MySQL
    database: 'neurochat_db', // Usando o banco existente
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = pool;