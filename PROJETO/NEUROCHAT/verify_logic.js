const messageRepository = require('./src/repositories/messageRepository');

async function testLogic() {
    console.log("Testing _mapMessage logic...");
    const msgNone = messageRepository._mapMessage({ text: 'Hello', file_name: 'test.jpg' });
    console.log("Normal message is_deleted:", msgNone.is_deleted);

    const msgDeleted = messageRepository._mapMessage({ text: '🚫 Mensagem apagada', file_name: null });
    console.log("Deleted message is_deleted:", msgDeleted.is_deleted);

    console.log("\nTesting getChatMedia query filter...");
    // Just verifying the query string was updated correctly in the code
    if (messageRepository.getChatMedia.toString().includes("AND text != '🚫 Mensagem apagada'")) {
        console.log("getChatMedia filter: OK");
    } else {
        console.log("getChatMedia filter: FAILED");
    }

    console.log("\nTesting softDelete logic...");
    // softDelete should update text to '🚫 Mensagem apagada' AND file_name to NULL
    if (messageRepository.softDelete.toString().includes("text = '🚫 Mensagem apagada'") && 
        messageRepository.softDelete.toString().includes("file_name = NULL")) {
        console.log("softDelete logic: OK");
    } else {
        console.log("softDelete logic: FAILED");
    }
}

testLogic();
