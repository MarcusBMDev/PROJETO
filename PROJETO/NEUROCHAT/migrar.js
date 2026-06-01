const sqlite3 = require('sqlite3').verbose();
const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config();

// Caminho do banco antigo
const SQLITE_PATH = path.join(__dirname, 'chat.db');

async function migrate() {
    console.log("🚀 Iniciando migração de SQLite para MySQL...");

    // 1. Conexão com SQLite (Origem)
    const sqlite = new sqlite3.Database(SQLITE_PATH, sqlite3.OPEN_READONLY, (err) => {
        if (err) {
            console.error("❌ Erro ao abrir chat.db. Verifique se o arquivo existe na pasta.");
            process.exit(1);
        }
    });

    // Função para transformar comandos do SQLite em Promessa (async/await)
    const sqlGet = (query) => new Promise((resolve, reject) => {
        sqlite.all(query, (err, rows) => {
            if (err) reject(err); else resolve(rows);
        });
    });

    // 2. Conexão com MySQL (Destino)
    let mysqlConn;
    try {
        mysqlConn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME, // Vai pegar 'neurochat_db' do seu .env
            port: process.env.DB_PORT || 3306
        });
        console.log("✅ Conectado ao MySQL.");
    } catch (e) {
        console.error("❌ Erro ao conectar no MySQL. Verifique o .env", e.message);
        process.exit(1);
    }

    try {
        // Desativa checagem de chaves estrangeiras para permitir inserção fora de ordem
        await mysqlConn.query("SET FOREIGN_KEY_CHECKS=0");

        // --- A. MIGRAR USUÁRIOS ---
        console.log("⏳ Migrando Usuários...");
        const users = await sqlGet("SELECT * FROM users");
        for (const u of users) {
            await mysqlConn.execute(`
                INSERT IGNORE INTO users (id, username, password, department, photo, is_super_admin) 
                VALUES (?, ?, ?, ?, ?, ?)
            `, [u.id, u.username, u.password, u.department, u.photo, u.is_super_admin]);
        }
        console.log(`   > ${users.length} usuários processados.`);

        // --- B. MIGRAR GRUPOS ---
        console.log("⏳ Migrando Grupos...");
        const groups = await sqlGet("SELECT * FROM groups");
        for (const g of groups) {
            await mysqlConn.execute(`
                INSERT IGNORE INTO groups (id, name, created_by, is_broadcast) 
                VALUES (?, ?, ?, ?)
            `, [g.id, g.name, g.created_by, g.is_broadcast || 0]);
        }
        console.log(`   > ${groups.length} grupos processados.`);

        // --- C. MIGRAR MEMBROS ---
        console.log("⏳ Migrando Membros dos Grupos...");
        const members = await sqlGet("SELECT * FROM group_members");
        for (const m of members) {
            const lastView = m.last_view ? new Date(m.last_view) : new Date();
            await mysqlConn.execute(`
                INSERT IGNORE INTO group_members (group_id, user_id, is_admin, last_view) 
                VALUES (?, ?, ?, ?)
            `, [m.group_id, m.user_id, m.is_admin, lastView]);
        }
        console.log(`   > ${members.length} membros processados.`);

        // --- D. MIGRAR MENSAGENS ---
        console.log("⏳ Migrando Mensagens (Isso pode demorar)...");
        const msgs = await sqlGet("SELECT * FROM messages");
        for (const m of msgs) {
            // Preenche campos que podem não existir no SQLite antigo com padrão
            const replyTo = m.reply_to_id || null;
            const isPinned = m.is_pinned || 0;
            const isEdited = m.is_edited || 0;
            const isDeleted = m.is_deleted || 0;
            const fileName = m.file_name || null;
            const msgType = m.msg_type || 'text';
            const timestamp = m.timestamp ? new Date(m.timestamp) : new Date();

            await mysqlConn.execute(`
                INSERT IGNORE INTO messages 
                (id, user_id, text, target_id, target_type, is_read, is_edited, is_deleted, is_pinned, reply_to_id, msg_type, file_name, timestamp) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                m.id, m.user_id, m.text, m.target_id, m.target_type, 
                m.is_read, isEdited, isDeleted, isPinned, replyTo, msgType, fileName, timestamp
            ]);
        }
        console.log(`   > ${msgs.length} mensagens processadas.`);

        // --- E. MIGRAR REAÇÕES (SE EXISTIR) ---
        try {
            console.log("⏳ Verificando Reações...");
            // Verifica se a tabela existe no SQLite antes de tentar ler
            const reacts = await sqlGet("SELECT * FROM message_reactions");
            for (const r of reacts) {
                await mysqlConn.execute(`
                    INSERT IGNORE INTO message_reactions (id, message_id, user_id, reaction) 
                    VALUES (?, ?, ?, ?)
                `, [r.id, r.message_id, r.user_id, r.reaction]);
            }
            console.log(`   > ${reacts.length} reações processadas.`);
        } catch (e) {
            console.log("   > Tabela de reações não encontrada no SQLite ou vazia (ignorando).");
        }

        console.log("✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!");

    } catch (err) {
        console.error("❌ Erro fatal durante a migração:", err);
    } finally {
        // Reativa proteções e fecha conexões
        await mysqlConn.query("SET FOREIGN_KEY_CHECKS=1");
        await mysqlConn.end();
        sqlite.close();
    }
}

migrate();