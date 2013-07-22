var Passphrase, socket;

$.fn.refresh = function() {
  return this.toggle().removeAttr("style");
};

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
  if (!isUp) {
    return enabledStatus.parent().parent().attr("data-disabled", true);
  } else {
    return enabledStatus.parent().parent().removeAttr("data-disabled");
  }
});

socket.on('capacity', function(capacity) {
  return $('[data-capacity]').attr("data-capacity", capacity).refresh();
});

socket.on('population', function(population) {
  return $("[data-population]").attr("data-population", population).refresh();
});

socket.on('time', function(time) {
  var isDay, newClass, oldClass;
  isDay = time.localeCompare("DAY") === 0;
  newClass = isDay ? "text-success" : "text-warning";
  oldClass = isDay ? "text-warning" : "text-success";
  return $("#time-description").text(time).addClass(newClass).removeClass(oldClass);
});

socket.on('sleep', function(count) {
  return $("[data-sleeping]").attr("data-sleeping", count).refresh();
});

socket.on('player list', function(list) {
  var playerlist;
  playerlist = $("#playerlist").html("");
  return _.each(list, function(player) {
    return playerlist.append("<li>" + player + "</li>");
  });
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