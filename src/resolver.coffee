'use strict'

class TimeoutError extends Error
  constructor: (@tag, @originTag, @timeout) ->
    if @originTag
      originText = "(by #{@originTag}) "
    @message = "Timeout for tag '#{@tag} #{originText}after #{@timeout}ms"


class Resolver
  constructor: (options) ->
    options = options or {}
    @map = {}
    @timeout = options.timeout

  getEntry: (tag) ->
    @map[tag]

  createEntry: (tag, err, data) ->
    @map[tag] =
      err: err
      data: data
      queue: []

  resolveEntry: (entry, err, data) ->
    if entry.timer?
      clearTimeout entry.timer
      entry.timer = null
    entry.err = err
    entry.data = data
    while entry.queue.length > 0
      done = entry.queue.shift()
      done entry.err, entry.data
    entry.resolved = true
    return

  pull: (tag, originTag, done) ->
    entry = @map[tag]
    if entry?
      if entry.resolved
        done entry.err, entry.data
        return
    else
      entry = @createEntry(tag)
    entry.queue.push done
    if @timeout?
      timerFn = => @resolveEntry entry, new TimeoutError tag, originTag, @timeout
      entry.timer = setTimeout timerFn, @timeout
    return

  push: (tag, err, data) ->
    entry = @map[tag]
    if entry?
      if entry.resolved
        throw new Error "duplicate tag: '#{tag}'"
      @resolveEntry entry, err, data
    else
      entry = @createEntry(tag, err, data)
      entry.resolved = true
    return

factory = (options) ->
  new Resolver options

factory.Resolver = Resolver
factory.TimeoutError = TimeoutError

module.exports = factory
