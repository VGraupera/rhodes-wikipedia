var toolbarOptionalButton = function() {
  $.get("/app/WikipediaPage/history", function(data) {
    $('#history_box').html(data).show('fast');
    $('#wrapper').hide();
    return 'false';
  })
}