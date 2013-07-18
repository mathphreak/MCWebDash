var Passphrase, socket;

socket = io.connect('');

socket.on('server status changed', function(isUp) {
  var enabledStatus, newClass, newText, oldClass;
  oldClass = isUp ? "text-error" : "text-success";
  newClass = isUp ? "text-success" : "text-error";
  newText = isUp ? "enabled" : "disabled";
  enabledStatus = $("#enabled-status");
  enabledStatus.removeClass(oldClass);
  enabledStatus.addClass(newClass);
  enabledStatus.text(newText.toUpperCase());
  if (isUp) {
    return enabledStatus.parent().attr("data-enabled", true);
  } else {
    return enabledStatus.parent().removeAttr("data-enabled");
  }
});

socket.on('capacity', function(capacity) {
  return document.querySelector('#capacity').innerHTML = "" + capacity;
});

socket.on('population', function(population) {
  return document.querySelector("#population").innerHTML = "" + population;
});

Passphrase = Backbone.Model.extend({
  canRun: function(commandString) {
    return true;
  }
});

$(function() {
  return $("#passphrase-form").submit(function() {
    $("#passphrase-form .btn").button('loading');
    setTimeout(function() {
      return $.post('/attempt', {
        phrase: $("#passphrase-form input").val()
      }).done(function() {
        $("#passphrase-form .btn").val('OK!');
        return $("#showhash .modal-body").load('/hash');
      }).fail(function() {
        return $("#passphrase-form .btn").val('Not allowed!');
      }).always(function() {
        return setTimeout((function() {
          return $("#passphrase-form .btn").button('reset');
        }), 2000);
      });
    }, 250);
    return false;
  });
});


//# sourceMappingURL=/javascripts/app.map
//@ sourceMappingURL=/javascripts/app.map