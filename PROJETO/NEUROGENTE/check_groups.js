const db = require('./src/config/db');
db.query("SELECT id, name FROM `groups` LIMIT 50", (err, results) => {
    if (err) {
        console.error("Error querying groups:", err);
    } else {
        console.log("GROUPS IN DATABASE:");
        console.log(JSON.stringify(results, null, 2));
    }
    process.exit(0);
});
