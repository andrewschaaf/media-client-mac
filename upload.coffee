
fs = require 'fs'
http = require 'http'
{spawn} = require 'child_process'


timeoutSet = (x, y) -> setTimeout y, x


getLatestPath = () ->
  dir = "/Users/a/Desktop"#TEMP
  filenames = []
  for filename in fs.readdirSync dir
    if filename.match /^MediaClient_[0-9]+.mov$/
      filenames.push filename
  if filenames.length == 0
    null
  else
    filenames.sort()
    filename = filenames[filenames.length - 1]
    "#{dir}/#{filename}"


main = () ->
  
  path = process.argv[2]
  if not path
    path = getLatestPath()
  
  #TODO: wait for ARGV-specified path to exist
  timeoutSet 1000, () ->
    
    # Start upload
    opt = {
      method: 'POST'
      host: 'localhost'
      port: 3000
      path: '/api/upload'
    }
    req = http.request opt, (res) ->
      console.log 'got response'
    
    p = spawn "/usr/bin/tail", ['-c', '+0', '-f', path]
    
    p.stdout.on 'data', (data) ->
      console.log "tail -f: #{data.length} more bytes"
      req.write data
    
    p.stderr.on 'data', (data) ->
      console.log data.toString()
    
    p.on 'exit', () ->
      console.log "**** tail exited"
    
    whenDone = () ->
      #TODO wait until we've sent the right number of bytes
      timeoutSet 1000, () ->
        req.end()
    
    process.on 'SIGTERM', whenDone
    process.on 'SIGINT', whenDone

main()
