const pool = require('./src/config/database');
async function checkUsers() {
    const [rows] = await pool.query("SELECT id, username, department FROM users LIMIT 10;");
    console.log(JSON.stringify(rows, null, 2));
    process.exit(0);
}
checkUsers();
