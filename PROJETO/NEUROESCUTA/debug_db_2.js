const mysql = require('mysql2');
const connection = mysql.createConnection({ host: '127.0.0.1', user: 'root', password: '', database: 'neurochat_db' });
connection.connect();
connection.query('SELECT username, password FROM users LIMIT 10', (err, results) => {
    if (err) console.error(err);
    else console.log("USERS ROW:", results);
    connection.end();
});
