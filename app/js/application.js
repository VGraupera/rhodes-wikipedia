var toolbarOptionalButton = function() {
  $.get("/app/WikipediaPage/history?ajax=true", function(data) {
    $('#history_box').html(data).show();
    $('#wrapper').hide();
    scroll(0,0);
    return 'false';
  })
}

var clearHistory = function() {
  $.get("/app/WikipediaPage/history?clear=true&ajax=true", function(data) {
    $('#history_box').html(data)
  })
}

var closeHistory = function() {
  $('#history_box').hide();
  $('#wrapper').show();
}