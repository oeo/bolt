const crypto = require('crypto')

const _ = require('lodash')

function merkleHash(arr) {
  if (!arr.length) {
    return null
  }

  arr = _.map(arr, (item) => {
    return JSON.parse(JSON.stringify(item))
  })

  if (arr.length === 1) {
    let r = crypto.createHash('sha256').update(Buffer.from([arr[0]])).digest();
    return r
  }

  const mid = Math.floor(arr.length / 2);
  const left = merkleHash(arr.slice(0, mid));
  const right = merkleHash(arr.slice(mid));

  const r = crypto.createHash('sha256').update(Buffer.concat([left, right])).digest();
  return r
}

function merkleHashStr(arr) {
  if (arr === null || !arr || !arr.length)
    return null

  let merkleBuf = merkleHash(arr).toString('hex')
  return merkleBuf
}

module.exports = {
  merkleHash,
  merkleHashStr,
}