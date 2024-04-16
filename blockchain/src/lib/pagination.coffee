# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
_ = require 'lodash'

pagination = (opts = {}) ->
  opts.total ||= 0
  opts.curPage ||= 0
  opts.perPage ||= 100
  opts.numButtons ||= 2
  opts.showFirst ||= true
  opts.showLast ||= true
  opts.arrowMode ||= false

  if _.isString(opts.curPage)
    try opts.curPage = parseInt opts.curPage

  pagesTotal = opts.total / opts.perPage
  pagesTotal = Math.ceil(pagesTotal) - 1

  pages = []

  curOffset = (opts.perPage * opts.curPage)

  for x in [0..pagesTotal]
    tmp = [
      (opts.perPage * x)
      (opts.perPage * (x + 1))
    ]

    tmp[1] = opts.total if tmp[1] >= opts.total

    tmpObj = {
      pageNum: x
      label: x + 1
      minOffset: tmp[0]
      maxOffset: tmp[1]
    }

    tmpObj.first = true if tmpObj.pageNum is 0
    tmpObj.last = true if tmpObj.pageNum is pagesTotal

    pages.push tmpObj

  result = {
    labelIndexMin: do ->
      min = opts.perPage * opts.curPage
      min = 1 if min is 0
      min
    labelIndexMax: do ->
      max = (opts.curPage + 1) * opts.perPage
      max = opts.total if max > opts.total
      max
    offset: (opts.perPage * opts.curPage)
    page: opts.curPage
    pageLabel: opts.curPage + 1
    pageTotalLabel: pagesTotal + 1
    total: opts.total
    links: []
  }

  used = []
  links = []

  activePageIndex = null

  i = 0
  for page in pages
    if page.pageNum is opts.curPage
      activePageIndex = i
      break
    ++i

  activePage = _.clone pages[activePageIndex]
  activePage.active = true

  used.push 'first' if activePage.first
  used.push 'last' if activePage.last

  try delete activePage.first
  try delete activePage.last

  links.push activePage
  used.push activePageIndex

  for x in [1..opts.numButtons]
    tmpIndex = activePageIndex - x

    if pages[tmpIndex] and tmpIndex not in used
      pageClone = _.clone pages[tmpIndex]
      try delete pageClone.first
      try delete pageClone.last
      links.push pageClone
      used.push 'last' if pages[tmpIndex].last
      used.push 'first' if pages[tmpIndex].first
      used.push tmpIndex

    tmpIndex = activePageIndex + x

    if pages[tmpIndex] and tmpIndex not in used
      pageClone = _.clone pages[tmpIndex]
      try delete pageClone.first
      try delete pageClone.last
      links.push pageClone
      used.push 'last' if pages[tmpIndex].last
      used.push 'first' if pages[tmpIndex].first
      used.push tmpIndex

  if opts.showFirst and 'first' not in used
    links.push(_.find(pages, first: true)) unless _.find(links, first: true)

  if opts.showLast and 'last' not in used
    links.push(_.find(pages, last: true)) unless _.find(links, last: true)

  result.links = _.sortBy links, 'pageNum'
  result.links = [] if result.links.length is 1

  # only previous and next arrows
  delete result.links if result.links.length is 1

  if opts.arrowMode and result.links
    newLinks = []

    i = 0
    for link in result.links
      if not link.active
        ++i
      else
        break

    if result.links[i - 1]
      tmpItem = _.clone result.links[i - 1]
      tmpItem.prev = true
      newLinks.push tmpItem

    if result.links[i + 1]
      tmpItem = _.clone result.links[i + 1]
      tmpItem.next = true
      newLinks.push tmpItem

    result.links = newLinks

  if result.total is 0
    result.links = []
    result.pageTotalLabel = 1
    result.hasItems = false
  else
    result.hasItems = true

  return result

module.exports = pagination

###
opts = {
  total: 70
  curPage: 6
  perPage: 10
  numButtons: 1
  showFirst: true
  showLast: true
}

console.log pagination opts
###

