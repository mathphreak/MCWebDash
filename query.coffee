# Thanks Dinnerbone!

dgram = require "dgram"
_ = require "underscore"
Q = require "q"
events = require "events"

module.exports = class MinecraftQuery
    MAGIC_PREFIX: '\xFE\xFD'
    PACKET_TYPE_CHALLENGE: 9
    PACKET_TYPE_QUERY: 0
    HUMAN_READABLE_NAMES:
        game_id    : "Game Name",
        gametype   : "Game Type",
        motd       : "Message of the Day",
        hostname   : "Server Address",
        hostport   : "Server Port",
        map        : "Main World Name",
        maxplayers : "Maximum Players",
        numplayers : "Players Online",
        players    : "List of Players",
        plugins    : "List of Plugins",
        raw_plugins: "Raw Plugin Info",
        software   : "Server Software",
        version    : "Game Version"
    
    constructor: (host, port, id=0, retries=2) ->
        @addr = [host, port]
        @id = id
        id_packed = new Buffer 4
        id_packed.writeUInt32BE(id, 0)
        @id_hex = id_packed.toString 'hex'
        challenge_packed = new Buffer 4
        challenge_packed.writeUInt32BE(0, 0)
        @challenge_hex = challenge_packed.toString 'hex'
        @retries = 0
        @max_retries = retries
        
        @PacketGET = new events.EventEmitter()
        
        @socket = dgram.createSocket('udp4')
        @socket.bind()
        @socket.on 'message', (msg) =>
            @PacketGET.emit("GET", msg)
    
    send_raw: (data, cb) =>
        msg = new Buffer(data.length + 2)
        msg[0] = 0xFE
        msg[1] = 0xFD
        data.copy(msg, 2)
        @socket.send msg, 0, msg.length, @addr[1], @addr[0], =>
            cb()
    
    send_packet: (type, data, cb) =>
        packetAlmostHexString = "00#{ @id_hex }#{ @challenge_hex }#{data.toString('hex')}"
        result = new Buffer packetAlmostHexString, 'hex'
        result.writeUInt8(type, 0)
        @send_raw result, =>
            cb()
    
    send_packet_empty: (type, cb) =>
        @send_packet type, new Buffer(0), =>
            cb()
    
    read_packet: (cb) =>
        @PacketGET.once 'GET', (buff) =>
            type = buff.readInt8(0)
            id = buff.readInt32BE(1)
            cb(type, id, buff[5..])
    
    handshake: (cb, bypass_retries=no) =>
        @send_packet_empty @PACKET_TYPE_CHALLENGE, =>
            try
                @read_packet (type, id, buff) =>
                    challengeBuffer = buff.slice(0)
                    @challenge = parseInt(challengeBuffer.toString())
                    challenge_packed = new Buffer(4)
                    challenge_packed.writeUInt32BE(@challenge, 0)
                    @challenge_hex = challenge_packed.toString('hex')
                    cb()
            catch err
                if not bypass_retries
                    @retries += 1
                
                if @retries < @max_retries
                    @handshake(cb, bypass_retries)
                    return
                else
                    throw err
    
    ensureHandshake: (cb) =>
        if @challenge?
            cb()
        else
            @handshake =>
                cb()
    
    get_rules: (cb) =>
        @ensureHandshake =>
            @send_packet @PACKET_TYPE_QUERY, @id_hex, =>
                try
                    @read_packet (type, id, buff) =>
                        data = {}
                
                        buff = buff[11..] # splitnum + 2 ints
                        [items, players] = buff.toString().split('\x00\x00\x01player_\x00\x00') # Shamefully stole from https://github.com/barneygale/MCQuery
                        
                        if items[..8] == 'hostname'
                            items = 'motd' + items[8..]
                        
                        items = items.split '\x00'
                        data = _.object(_.filter(items, (obj, i) => i%2 is 0), _.filter(items, (obj, i) => i%2 is 1))
                        
                        players = players[..-2]
                        
                        if players
                            data['players'] = players.split('\x00')
                        else
                            data['players'] = []
                        
                        for key in ['numplayers', 'maxplayers', 'hostport']
                            try
                                data[key] = int(data[key])
                            catch err
                                # who cares?
                        
                        data['raw_plugins'] = data['plugins']
                        #[data['software'], data['plugins']] = @parse_plugins(data['raw_plugins'])
                        
                        cb data
                catch err
                    @retries += 1
                    if @retries < @max_retries
                        @handshake((=> @get_rules()), yes)
                    else
                        throw err
    
    parse_plugins: (raw) =>
        parts = raw.split(':', 1)
        server = parts[0].strip()
        plugins = []
        
        if len(parts) == 2
            plugins = parts[1].split(';')
            plugins = map(((s) => s.strip()), plugins)
        
        return [server, plugins]