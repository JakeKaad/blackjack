$(document).ready(function(){
	$(document).on('click', 'form#player_form player_hit_button', function(){
		$.ajax({
			type: 'POST',
			url: '/game/player/hit_or_stay'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false;
	});
	$(document).on('click', 'form#dealer_form dealer_hit_button', function(){
		$.ajax({
			type: 'POST',
			url: '/dealer/hit'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false
	});
});