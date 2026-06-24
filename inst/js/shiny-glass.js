// Keep native <select> menus above sibling inputs inside cards
$(document).on("focus mousedown", ".card .form-select", function () {
  var container = $(this).closest(".shiny-input-container");
  container.addClass("glass-select-open");
  container.siblings(".shiny-input-container").removeClass("glass-select-open");
});

$(document).on("blur change", ".card .form-select", function () {
  var container = $(this).closest(".shiny-input-container");
  setTimeout(function () {
    if (!container.find(".form-select").is(":focus")) {
      container.removeClass("glass-select-open");
    }
  }, 150);
});