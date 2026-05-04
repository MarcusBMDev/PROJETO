const db = require('./src/config/db');

console.log("Iniciando teste de Pool...");

db.query('SELECT 1 + 1 AS result', (err, results) => {
    if (err) {
        console.error("❌ Erro no teste de pool:", err);
        process.exit(1);
    } else {
        console.log("✅ Conexão via Pool funcionando! Resultado:", results[0].result);
        process.exit(0);
    }
});
