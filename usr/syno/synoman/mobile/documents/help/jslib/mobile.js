$(document).ready(function() {
	$('a[name]').click(function(event) {
		var target = event.target,
			name = $(target).attr('name');

		event.preventDefault();
		$('#' + name).toggle();
	});
});
