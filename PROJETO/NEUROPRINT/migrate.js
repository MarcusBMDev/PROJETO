const pool = require('./src/config/database');

async function migrate() {
    try {
        console.log('Starting migration...');
        
        // Check if is_duplex exists
        const [columns] = await pool.query("DESCRIBE neuroprint_jobs;");
        const hasDuplex = columns.some(c => c.Field === 'is_duplex');
        const hasTwoPerPage = columns.some(c => c.Field === 'two_per_page');

        if (!hasDuplex) {
            console.log('Adding column is_duplex...');
            await pool.query("ALTER TABLE neuroprint_jobs ADD COLUMN is_duplex TINYINT(1) DEFAULT 0 AFTER color_mode;");
            console.log('✅ Column is_duplex added.');
        } else {
            console.log('ℹ️ Column is_duplex already exists.');
        }

        if (!hasTwoPerPage) {
            console.log('Adding column two_per_page...');
            await pool.query("ALTER TABLE neuroprint_jobs ADD COLUMN two_per_page TINYINT(1) DEFAULT 0 AFTER is_duplex;");
            console.log('✅ Column two_per_page added.');
        } else {
            console.log('ℹ️ Column two_per_page already exists.');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error during migration:', error);
        process.exit(1);
    }
}

migrate();
