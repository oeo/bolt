const crypto = require('crypto');

function safeModifiedScrypt(input, salt, callback) {
  // Begin with standard Scrypt parameters
  const N = 16384; // Fixed for comparison
  const r = 8;
  const p = 1;

  // Unique modification: Append a hash of the input to the input itself
  const uniqueInput = Buffer.concat([
    Buffer.from(input),
    crypto.createHash('sha256').update(input).digest(),
  ]);

  // Proceed with the Scrypt hash using the uniquely modified input
  crypto.scrypt(uniqueInput, salt, 64, { N, r, p }, (err, derivedKey) => {
    if (err) throw err;
    callback(derivedKey.toString('hex'));
  });
}


function normalScrypt(input, salt, callback) {
  // Use Node.js's built-in crypto.scrypt with standard parameters
  crypto.scrypt(input, salt, 64, { N: 16384, r: 8, p: 1 }, (err, derivedKey) => {
    if (err) throw err;
    callback(derivedKey.toString('hex'));
  });
}

// Example usage
const input = 'example';
const salt = '';

safeModifiedScrypt(input, salt, (result) => {
  console.log({modified:result});
});

normalScrypt(input, salt, (result) => {
  console.log({normal:result});
});

