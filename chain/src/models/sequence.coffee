mongoose = require 'mongoose'

SequenceSchema = new mongoose.Schema
  name:
    type: String
    required: true
  value:
    type: Number
    required: true
    default: 0

Sequence = mongoose.model 'Sequence', SequenceSchema
module.exports = Sequence

