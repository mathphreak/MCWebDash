module.exports = (server) ->
    dgram = require "dgram"
    events = require 'events'

    io = require("socket.io").listen(server)

    io.enable('browser client minification')
    io.enable('browser client gzip') unless require('os').type() is 'Windows_NT'
    io.enable('browser client etag')

    ServerStatus =
        up: no
        capacity: 0
        population: 0
        emitter: new events.EventEmitter

    setUp = (isUp) ->
        ServerStatus.up = isUp
        ServerStatus.emitter.emit('setUp', isUp)
        setPopulation 0

    setCapacity = (capacity) ->
        ServerStatus.capacity = capacity
        ServerStatus.emitter.emit('setCapacity', capacity)

    setPopulation = (population) ->
        ServerStatus.population = population
        ServerStatus.emitter.emit('setPopulation', population)

    io.sockets.on 'connection', (socket) ->
        ServerStatus.emitter.on 'setUp', (isUp) -> socket.emit('server status changed', isUp)
        ServerStatus.emitter.on 'setCapacity', (capacity) -> socket.emit('capacity', capacity)
        ServerStatus.emitter.on 'setPopulation', (population) -> socket.emit('population', population)

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
    
    return ServerStatus