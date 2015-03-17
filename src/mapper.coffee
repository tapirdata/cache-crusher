'use strict'

path = require 'path'

escapeRegExp = (s) ->
  s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

class Entry
  constructor: (options) ->
    @urlRoot = options.urlRoot
    @destPattern = options.destPattern

  map: (destPath) ->
    match = @destPattern.exec destPath
    if not match?
      return
    path.join @urlRoot, match[1]


class Mapper 

  constructor: (counterparts, options) ->
    entries = []
    for cp in counterparts
      destPattern = new RegExp "^#{escapeRegExp cp.dest}(.*)"
      entry = new Entry
        urlRoot: cp.url
        destPattern: destPattern
      entries.push entry
    @entries = entries

  map: (destPath) ->  
    for entry in @entries
      urlPath = entry.map destPath
      if urlPath?
        return urlPath
    throw new Error "no mapping found for path '#{destPath}'"


factory = (counterparts, options) ->
  new Mapper counterparts, options

factory.Mapper = Mapper

# m1 = factory [
#   (url:'/vendor', dest:'.tmp/dev/client/scripts/vendor')
#   (url: '/app', dest: '.tmp/dev/client')
# ]
# 


module.exports = factory

  

