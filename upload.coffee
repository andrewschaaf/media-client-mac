
fs = require 'fs'
http = require 'http'
{spawn} = require 'child_process'

console.log 'Starting upload.coffee...'

fps = parseInt process.argv[2], 10

token = "#{new Date().getTime()}"

opt = {
  method: 'POST'
  host: 'localhost'
  port: 3000
  path: "/stream/#{token}/upload/"
}
req = http.request opt, (res) ->
  console.log 'got upload response'
p = spawn '/usr/local/bin/ffmpeg', [
  '-r', "#{fps}",
  '-f', 'image2pipe',
  '-vcodec', 'ppm',
  '-i', '-',
  '-vcodec', 'libx264',
  '-f', 'mpegts',
  '-'
]
console.log "*** PID #{p.pid}"
process.stdin.resume()
process.stdin.pipe p.stdin

p.on 'exit', () ->
  console.log '**** ffmpeg exited'

console.log 'Started.'

p.stdout.pipe req

