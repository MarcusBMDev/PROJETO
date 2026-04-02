const pool = require('./src/config/database');

async function migrate() {
    try {
        await pool.query("ALTER TABLE neuroprint_jobs ADD COLUMN sector VARCHAR(100) AFTER user_id;");
        console.log('✅ Column "sector" added to neuroprint_jobs.');
        process.exit(0);
    } catch (error) {
        if (error.code === 'ER_DUP_COLUMN_NAME') {
            console.log('⚠️ Column "sector" already exists.');
            process.exit(0);
        }
        console.error('❌ Error adding column sector:', error);
        process.exit(1);
    }
}

migrate();
