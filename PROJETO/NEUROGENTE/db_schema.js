const mysql = require('mysql2');

const connection = mysql.createConnection({
    host: '127.0.0.1', 
    user: 'root',
    password: '',
    database: 'neurochat_db' // same db config as neurochat? usually rh or neurochat
});

connection.query("DESCRIBE rh_solicitacoes", (err, results) => {
    if (err) {
        console.error("Error describing table:", err.message);
    } else {
        console.log("SCHEMA:");
        console.table(results);
    }
    connection.end();
});
