// vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
const IPFS = require('ipfs');

async function startIPFS() {
    const node = await IPFS.create();
    const nodeId = await node.id();
    console.log(`My IPFS node ID: ${nodeId.id}`);

    // Example: Subscribe to a blockchain topic
    const topic = 'my-blockchain-topic';
    await node.pubsub.subscribe(topic, (message) => {
        console.log(`Received message: ${String(message.data)}`);
    });

    // Now, your node is part of the IPFS network and can discover peers, publish, and receive messages.
}

startIPFS().catch(console.error);


