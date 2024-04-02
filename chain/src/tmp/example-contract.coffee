# mixins
time = ->
  Math.floor(new Date().getTime()/1000)

# decorators
owner = (fn) ->
  (args..., transaction) ->
    if transaction.from != @owner
      throw 'Only the owner can call this function'
    @transaction = transaction
    fn.apply(this, args)

payable = (fn) ->
  (args..., transaction) ->
    if +transaction.amount < 0
      throw 'Invalid payment amount'
    @transaction = transaction
    fn.apply(this, args)

external = (fn) ->
  (args..., transaction) ->
    @transaction = transaction
    fn.apply(this, args)

view = (fn) ->
  (args...) ->
    fn.apply(this, args)

# example smart contract
class PollContract

  state: {
    name: 'feature priority'
    options: [
      'add contracts'
      'add privacy'
      'add block explorer'
    ]
    votes: []
    donations: 0
    memo: 'this is the default memo'
    startTime: time()
    endTime: time() + (3600 * 3)
  }

  constructor: (initialState = {}) ->
    for k, v of initialState
      @state[k] = v

  # only callable by owner
  addPollOption: owner (option) ->
    if @_hasEnded() then throw 'Poll ended'

    if option in @state.options
      throw 'Option already exists'

    @state.options.push option

  # only callable by owner
  removePollOption: owner (option) ->
    if @_hasEnded() then throw 'Poll ended'

    newOptions = []

    for x in state.options
      continue if x is option
      newOptions.push x

    @state.options = newOptions

  # payable function 
  castVote: payable (option) ->
    if @_hasEnded() then throw 'Poll ended'

    if option !in @state.options
      throw 'Invalid option'

    for item in @state.votes
      if item[0] is @transaction.from
        throw 'This address has already voted'

    @state.votes.push [@transaction.from, option, @transaction.amount]

  pollResults: view () ->
    results = []

    for item in @state.options
      results[item] = {
        votes: 0
        donations: 0
        donatedAmount: 0
      }

    for item in @state.votes
      {address, option, donation} = item
      continue if !results[option]

      results[option].votes += 1

      if +donation
        results[option].donations += 1
        results[option].donatedAmount += +donation

    return results

  # callable by anyone willing to pay fees
  changeMemo: external (newMemo) ->
    @state.memo = newMemo
    @state.memoAuthor = @transaction.from

  # private function
  _hasEnded: ->
    return @state.ctime >= @state.endTime

##
if !module.parent
  contract = new PollContract({
    name: 'what should we do next?'
  })

  console.log contract
