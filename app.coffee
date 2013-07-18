
# 
# Module dependencies.
# 

express = require('express')
http = require('http')
path = require('path')
mongoose = require 'mongoose'
secrets = require './secrets'
Passphrase = require('./Passphrase')(null, mongoose)

app = express()

server = http.createServer(app)

ServerStatus = require("./ServerStatus")(server)

# all environments
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon())
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.cookieParser())
app.use(express.session(secret: secrets.session, store: new require("connect").session.MemoryStore()))
app.use(express.methodOverride())
app.use(app.router)
app.use(require("connect-coffee-script")(src: __dirname + "/public", bare: yes, sourceMap: yes))
app.use(require('less-middleware')(src: __dirname + '/public'))
app.use(express.static(path.join(__dirname, 'public')))

mongoose.connect 'mongodb://localhost/mcwebdash'

# development only
if 'development' == app.get('env')
    app.use(express.errorHandler());

app.get '/', (req, res) ->
    res.render 'index', {enabled: ServerStatus.up, population: ServerStatus.population, capacity: ServerStatus.capacity}

app.post '/attempt', (req, res) ->
    phrase = req.param 'phrase', ''
    
    if not phrase? or phrase.length < 1
        res.send 400
        return
    
    Passphrase.attempt phrase, (success, hash) ->
        req.session.hash = hash
        res.send 401 unless success
        res.send 200 if success

app.get '/hash', (req, res) ->
    hash = req.session.hash
    
    if hash?
        res.send 200, hash
    else
        res.send 401

server.listen(app.get('port'), -> console.log('Express server listening on port ' + app.get('port')))

Passphrase.initializeBasicData()