const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./chat.db');

db.serialize(() => {
    // Adiciona coluna para bloquear departamentos (Ex: "TI,RH")
    db.run("ALTER TABLE users ADD COLUMN blocked_departments TEXT DEFAULT ''", (err) => {
        if (!err) console.log("Coluna 'blocked_departments' criada com sucesso!");
        else console.log("Coluna já existe ou erro ignorável.");
    });
});
setTimeout(() => db.close(), 1000);