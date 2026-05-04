const mysql = require('mysql2');
const connection = mysql.createConnection({ host: '127.0.0.1', user: 'root', password: '', database: 'neurochat_db' });
connection.connect();
connection.query('DESCRIBE users', (err, results) => {
    if (err) console.error(err);
    else console.log("USERS SCHEMA:", results);
    
    connection.query('SELECT * FROM users LIMIT 1', (err, results) => {
        if (err) console.error(err);
        else console.log("USERS ROW:", results);
        connection.end();
    });
});
