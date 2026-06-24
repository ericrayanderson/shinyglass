// Keep native <select> menus above sibling inputs inside glass cards
$(document).on("focus mousedown", ".glass-card .form-select, .card .form-select", function () {
  var container = $(this).closest(".shiny-input-container");
  container.addClass("glass-select-open");
  container.siblings(".shiny-input-container").removeClass("glass-select-open");
});

$(document).on("blur change", ".glass-card .form-select, .card .form-select", function () {
  var container = $(this).closest(".shiny-input-container");
  setTimeout(function () {
    if (!container.find(".form-select").is(":focus")) {
      container.removeClass("glass-select-open");
    }
  }, 150);
});

$(document).on("click", ".shiny-glass-button", function () {
  var el = $(this);
  var curVal = parseInt(el.data("val") || 0, 10);
  el.data("val", curVal + 1);
  el.trigger("change");
});

(function () {
  var shinyGlassButton = new Shiny.InputBinding();

  $.extend(shinyGlassButton, {
    find: function (scope) {
      return $(scope).find(".shiny-glass-button");
    },
    getValue: function (el) {
      return parseInt($(el).data("val") || 0, 10);
    },
    subscribe: function (el, callback) {
      $(el).on("change.shiny-glass-button", function () {
        callback(true);
      });
    },
    unsubscribe: function (el) {
      $(el).off(".shiny-glass-button");
    },
    receiveMessage: function (el, data) {
      if (data.hasOwnProperty("label")) {
        $(el).text(data.label);
      }
      if (data.hasOwnProperty("disabled")) {
        $(el).prop("disabled", data.disabled);
      }
    }
  });

  Shiny.inputBindings.register(shinyGlassButton);
})();