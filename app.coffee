
# 
# Module dependencies.
# 

express = require('express')
http = require('http')
path = require('path')
events = require 'events'

dgram = require "dgram"

app = express()

server = http.createServer(app)

io = require("socket.io").listen(server)

io.enable('browser client minification')
io.enable('browser client gzip') unless require('os').type() is 'Windows_NT'
io.enable('browser client etag')

ServerStatus =
    up: no
    capacity: 0
    population: 0

ServerStatusEmitter = new events.EventEmitter

# all environments
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon())
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(require("connect-coffee-script")(src: __dirname + "/public", bare: yes, sourceMap: yes))
app.use(require('less-middleware')(src: __dirname + '/public'))
app.use(express.static(path.join(__dirname, 'public')))

# development only
if 'development' == app.get('env')
    app.use(express.errorHandler());

app.get '/', (req, res) ->
    res.render 'index', {enabled: ServerStatus.up, population: ServerStatus.population, capacity: ServerStatus.capacity}

dgramsocket = dgram.createSocket 'udp4'
dgramsocket.on 'message', (contents) ->
    message = contents[0]
    data = contents[1]
    switch message
        when 0 
            setUp(yes)
            setCapacity(data)
        when 1 then setUp(no)
        when 2 then setPopulation(data)
dgramsocket.bind(12823)

io.sockets.on 'connection', (socket) ->
    ServerStatusEmitter.on 'setUp', (isUp) -> socket.emit('server status changed', isUp)
    ServerStatusEmitter.on 'setCapacity', (capacity) -> socket.emit('capacity', capacity)
    ServerStatusEmitter.on 'setPopulation', (population) -> socket.emit('population', population)

setUp = (isUp) ->
    ServerStatus.up = isUp
    hadListeners = ServerStatusEmitter.emit('setUp', isUp)
    setPopulation 0

setCapacity = (capacity) ->
    ServerStatus.capacity = capacity
    ServerStatusEmitter.emit('setCapacity', capacity)

setPopulation = (population) ->
    ServerStatus.population = population
    ServerStatusEmitter.emit('setPopulation', population)

server.listen(app.get('port'), -> console.log('Express server listening on port ' + app.get('port')))