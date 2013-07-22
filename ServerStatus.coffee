module.exports = (server) ->
    dgram = require "dgram"
    events = require 'events'
    ServerQuery = require "./query"

    io = require("socket.io").listen(server)

    io.enable('browser client minification')
    io.enable('browser client gzip') unless require('os').type() is 'Windows_NT'
    io.enable('browser client etag')

    ServerStatus =
        up: no
        capacity: 0
        population: 0
        time: "DAY"
        sleeping: 0
        players: []
        emitter: new events.EventEmitter
    
    ServerStatus.emitter.setMaxListeners(0)
    
    updatePlayerList = ->
        query = new ServerQuery "127.0.0.1", 25565, 0x11111111
        query.get_rules (data) ->
            ServerStatus.players = data.players
            ServerStatus.emitter.emit("setPlayerList", ServerStatus.players)

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
        setTimeout(updatePlayerList, 500) if ServerStatus.up
    
    setTime = (time) ->
        ServerStatus.time = time
        ServerStatus.emitter.emit("setTime", time)
    
    setSleepCount = (count) ->
        ServerStatus.sleeping = count
        ServerStatus.emitter.emit("setSleepCount", count)

    io.sockets.on 'connection', (socket) ->
        upListener = (isUp) -> socket.emit('server status changed', isUp)
        capListener = (capacity) -> socket.emit('capacity', capacity)
        popListener = (population) -> socket.emit('population', population)
        timeListener = (time) -> socket.emit('time', time)
        listListener = (list) -> socket.emit 'player list', list
        sleepListener = (count) -> socket.emit 'sleep', count
        ServerStatus.emitter.on('setUp', upListener)
        .on('setCapacity', capListener)
        .on('setPopulation', popListener)
        .on('setTime', timeListener)
        .on('setPlayerList', listListener)
        .on('setSleepCount', sleepListener)
        socket.on 'disconnect', ->
            ServerStatus.emitter.removeListener('setUp', upListener)
            .removeListener('setCapacity', capListener)
            .removeListener('setPopulation', popListener)
            .removeListener('setTime', timeListener)
            .removeListener('setSleepCount', sleepListener)
            .removeListener('setPlayerList', listListener)

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
            when 3
                newTime = if data is 1 then 'DAY' else 'NIGHT'
                setTime(newTime) unless ServerStatus.time is newTime
            when 4 then setSleepCount(data)
    dgramsocket.bind(12823)
    
    return ServerStatus