const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Caminho do arquivo
const dbPath = path.join(__dirname, 'chat.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log("🔍 Lendo as últimas 5 mensagens do arquivo chat.db...");

db.all("SELECT id, text, timestamp FROM messages ORDER BY id DESC LIMIT 5", [], (err, rows) => {
    if (err) {
        console.error("❌ Erro ao ler:", err.message);
        return;
    }
    
    if (rows.length === 0) {
        console.log("⚠️ Nenhuma mensagem encontrada.");
    } else {
        console.log("✅ Últimas mensagens encontradas:");
        rows.forEach(r => {
            console.log(`[ID: ${r.id}] Data: ${r.timestamp} | Texto: ${r.text}`);
        });
    }
    db.close();
});