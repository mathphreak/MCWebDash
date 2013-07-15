socket = io.connect ''
socket.on 'server status changed', (isUp) ->
    oldClass = if isUp then "text-error" else "text-success"
    newClass = if isUp then "text-success" else "text-error"
    newText = if isUp then "enabled" else "disabled"
    enabledStatus = document.querySelector("#enabled-status")
    enabledStatus.classList.remove(oldClass)
    enabledStatus.classList.add(newClass)
    enabledStatus.innerHTML = newText.toUpperCase()

socket.on 'capacity', (capacity) ->
    document.querySelector('#capacity').innerHTML = "" + capacity

socket.on 'population', (population) ->
    document.querySelector("#population").innerHTML = "" + population