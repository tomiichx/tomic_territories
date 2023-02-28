$(() => {
	$(window).on('message', (event) => {
		const eventData = event.originalEvent.data;
		const territoryData = eventData.data[0];
		
		let territoryAttackers = 0;
		let territoryDefenders = 0;
		eventData.data.forEach((attender) => {
			if (attender.isPlayerDefender) {
				territoryDefenders++;
			} else {
				territoryAttackers++;
			}
		});

		switch (eventData.action) {
			case 'showUI':
				$('#scoreboard').show();
				$('#scoreboard-territory').html(territoryData.territoryName);
				$('#scoreboard-status').html(territoryData.territoryStatus);
				$('#scoreboard-attackers_count').html(territoryAttackers);
				$('#scoreboard-defenders_count').html(territoryDefenders);
				break;
			case 'hideUI':
				$('#scoreboard').fadeOut(500, () => {
					$('#scoreboard').hide();
				});
				break;
		}
	});
});
