const fs = require('fs');

try {
    const content = fs.readFileSync('c:/GitHub/PROJETO/neurochat_db.sql', 'utf8');
    
    // the date is 2026-04-24 14:08:40
    const rowEndRegex = /\(([^)]*'2026-04-24 14:08:40'[^)]*)\)/g;

    let match;
    while ((match = rowEndRegex.exec(content)) !== null) {
        console.log("Match:", match[1]);
    }
} catch (e) {
    console.error(e);
}
