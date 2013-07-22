$.fn.refresh = -> @toggle().removeAttr("style")

socket = io.connect ''
socket.on 'server status changed', (isUp) ->
    oldClass = if isUp then "text-error" else "text-success"
    newClass = if isUp then "text-success" else "text-error"
    newText = if isUp then "enabled" else "disabled"
    enabledStatus = $("#enabled-status")
    enabledStatus.removeClass(oldClass)
    enabledStatus.addClass(newClass)
    enabledStatus.text(newText.toUpperCase())
    if not isUp
        enabledStatus.parent().parent().attr("data-disabled", true)
    else
        enabledStatus.parent().parent().removeAttr("data-disabled")

socket.on 'capacity', (capacity) ->
    $('[data-capacity]').attr("data-capacity", capacity).refresh()

socket.on 'population', (population) ->
    $("[data-population]").attr("data-population", population).refresh()

socket.on 'time', (time) ->
    isDay = time.localeCompare("DAY") is 0
    newClass = if isDay then "text-success" else "text-warning"
    oldClass = if isDay then "text-warning" else "text-success"
    $("#time-description").text(time).addClass(newClass).removeClass(oldClass)

socket.on 'sleep', (count) ->
    $("[data-sleeping]").attr("data-sleeping", count).refresh()

socket.on 'player list', (list) ->
    playerlist = $("#playerlist").html("")
    _.each list, (player) -> playerlist.append("<li>#{player}</li>")

Passphrase = Backbone.Model.extend
    canRun: (commandString) -> yes

$ ->
    $("#passphrase-form").submit ->
        $("#passphrase-form .btn").button('loading')
        setTimeout ->
            $.post('/attempt', phrase: $("#passphrase-form input").val())
            .done(-> 
                $("#passphrase-form .btn").val('OK!')
                $("#showhash .modal-body").load('/hash')
            )
            .fail(-> $("#passphrase-form .btn").val('Not allowed!'))
            .always(-> setTimeout((-> $("#passphrase-form .btn").button('reset')), 2000))
        , 250
        no