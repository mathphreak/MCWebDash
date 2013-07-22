module.exports = (config, mongoose) ->
    crypto = require 'crypto'
    
    PassphraseSchema = new mongoose.Schema
        phrase: type: String
        powers:
            admin: type: Boolean
            commands: type: [mongoose.Schema.Types.ObjectId]
            player_arguments: type: [String]
    
    Passphrase = mongoose.model "Passphrase", PassphraseSchema
    
    attempt = (phrase, callback) ->
        shaSum = crypto.createHash 'md5'
        shaSum.update phrase
        
        hash = shaSum.digest 'hex'
        
        console.log 'Attempting to authenticate!'
        console.log " Phrase: #{ phrase }"
        console.log " Hash:   #{ hash }"
        
        Passphrase.findOne {phrase: hash}, (err, doc) -> callback(doc?, hash)
    
    create = (phrase, commands, player_arguments, admin = no) ->
        shaSum = crypto.createHash 'md5'
        shaSum.update phrase
        hash = shaSum.digest 'hex'
        
        Passphrase.findOne {phrase: hash}, (err, doc) ->
            if doc?
                console.log "Already found #{ phrase } in the database!"
            else
                console.log "Registering #{ phrase }..."
                passphrase = new Passphrase
                    phrase: hash
                    powers:
                        admin: admin
                        commands: commands
                        player_arguments: player_arguments
                passphrase.save (err) -> if err then console.log err else console.log "Registered #{ phrase }!"
                console.log "Tried to register #{ phrase }"
    
    initializeBasicData = ->
        create("AnotherPhrase", [], [], yes)
    
    get = (hash, callback) ->
        Passphrase.findOne {phrase: hash}, (err, doc) -> callback doc
    
    return {
        attempt: attempt
        create: create
        Passphrase: Passphrase
        initializeBasicData: initializeBasicData
        get: get
    }