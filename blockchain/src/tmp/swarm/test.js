// vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const Swarm = require('discovery-swarm');
const defaults = require('dat-swarm-defaults');

const app = express();
app.use(bodyParser.json());

const myPeerId = crypto.randomBytes(32);
console.log('myPeerId: ' + myPeerId.toString('hex'));

const config = defaults({
  id: myPeerId,
});

const swarm = Swarm(config);

// HTTP endpoint for receiving messages
app.post('/message', (req, res) => {
  const { from, to, type, data } = req.body;
  const message = { from, to, type, data };
  handleMessage(message);
  res.sendStatus(200);
});

// HTTP endpoint for connecting to a peer
app.post('/connect', (req, res) => {
  const { host, port } = req.body;
  const conn = swarm.connect(port, host);
  conn.on('data', (data) => {
    const message = JSON.parse(data);
    handleMessage(message);
  });
  res.sendStatus(200);
});

// Start the HTTP server
const httpPort = 8080;
app.listen(httpPort, () => {
  console.log(`HTTP server listening on port ${httpPort}`);
});

// Message handling logic
function handleMessage(message) {
  console.log('Received message:', message);
  // Handle the message based on its type
  // ...
}

// Join the swarm
const channel = 'myChannel';
swarm.join(channel);

swarm.on('connection', (conn, info) => {
  console.log('Connected to peer:', info.id.toString('hex'));
  conn.on('data', (data) => {
    const message = JSON.parse(data);
    handleMessage(message);
  });
});
