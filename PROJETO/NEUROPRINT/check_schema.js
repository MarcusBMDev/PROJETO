const pool = require('./src/config/database');

async function checkSchema() {
    try {
        const [rows] = await pool.query("DESCRIBE neuroprint_jobs;");
        console.log('Current schema of neuroprint_jobs:');
        rows.forEach(row => {
            console.log(`${row.Field} - ${row.Type}`);
        });
        process.exit(0);
    } catch (error) {
        console.error('❌ Error checking schema:', error);
        process.exit(1);
    }
}

checkSchema();
