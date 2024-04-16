# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
_ = require 'lodash'

###
config =
  difficultyDefault: 1
  difficultyChangeBlockConsideration: 10
  blockInterval: 60
  difficultyChangePercent: 5
  difficultyChangePercentDrastic: 10
###
config = require './../config'

class DifficultyCalculator
  constructor: (@blocks) ->

  calculateDifficulty: (blockHeight) ->
    if blockHeight is 0
      return config.difficultyDefault

    diffBlocks = @getRecentBlocks(blockHeight)

    if _.isEmpty diffBlocks
      return config.difficultyDefault

    currentDifficulty = _.get(diffBlocks, '[0].difficulty', config.difficultyDefault)
    averageElapsed = @calculateAverageElapsed(diffBlocks)

    adjustedDifficulty = currentDifficulty

    if currentDifficulty < config.difficultyDefault
      adjustedDifficulty = config.difficultyDefault

    if averageElapsed < config.blockInterval
      drastic = averageElapsed < config.blockInterval / 2
      changePercent = if drastic then config.difficultyChangePercentDrastic else config.difficultyChangePercent
      adjustedDifficulty += adjustedDifficulty * (changePercent / 100)
    else if averageElapsed > config.blockInterval
      drastic = averageElapsed > config.blockInterval * 2
      changePercent = if drastic then config.difficultyChangePercentDrastic else config.difficultyChangePercent
      adjustedDifficulty -= adjustedDifficulty * (changePercent / 100)

    return Math.ceil(adjustedDifficulty)

  getRecentBlocks: (blockHeight) ->
    _.chain(@blocks)
      .filter((block) -> block.height <= blockHeight)
      .orderBy(['height'], ['desc'])
      .take(config.difficultyChangeBlockConsideration)
      .value()

  calculateAverageElapsed: (blocks) ->
    elapsedTimes = _.map(blocks, 'time_elapsed')
    average = _.sum(elapsedTimes) / elapsedTimes.length
    return Math.ceil(average)

  median: (arr) ->
    sorted = _.sortBy(arr)
    mid = Math.floor(sorted.length / 2)
    if sorted.length % 2 isnt 0
      return sorted[mid]
    else
      return (sorted[mid - 1] + sorted[mid]) / 2

module.exports = DifficultyCalculator

