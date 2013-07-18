socket = io.connect ''
socket.on 'server status changed', (isUp) ->
    oldClass = if isUp then "text-error" else "text-success"
    newClass = if isUp then "text-success" else "text-error"
    newText = if isUp then "enabled" else "disabled"
    enabledStatus = $("#enabled-status")
    enabledStatus.removeClass(oldClass)
    enabledStatus.addClass(newClass)
    enabledStatus.text(newText.toUpperCase())
    if isUp
        enabledStatus.parent().attr("data-enabled", true)
    else
        enabledStatus.parent().removeAttr("data-enabled")

socket.on 'capacity', (capacity) ->
    document.querySelector('#capacity').innerHTML = "" + capacity

socket.on 'population', (population) ->
    document.querySelector("#population").innerHTML = "" + population

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