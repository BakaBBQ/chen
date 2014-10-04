$('#search_button').click(function(){
	redirect_to_search();
});

redirect_to_search = function(){
	var searchString = $('#search_text').val();
	window.location = "search?str=" + searchString;
}

$('#search_text').keypress(function(e){
    if ( e.which == 13 ) // Enter key = keycode 13
    {
		redirect_to_search();
        return false;
    }
});
