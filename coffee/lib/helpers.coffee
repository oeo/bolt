crypto = require 'crypto'
uuid = (require 'short-uuid').generate

time = -> Math.floor(Date.now() / 1000) 

timeBucket = (seconds) ->
  now = Math.floor(Date.now() / 1000)  # Get the current Unix epoch time in seconds
  bucketSize = seconds  # Set the bucket size to 60 seconds

  bucket = Math.floor(now / bucketSize) * bucketSize  # Calculate the current time bucket

  return bucket

sha256 = (val) ->
  return crypto.createHash('sha256').update(val).digest('hex')

module.exports = {
  timeBucket,
  sha256,
  uuid,
  time,
}
