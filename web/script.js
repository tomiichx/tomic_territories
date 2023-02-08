$(window).on("message", function (event) {
	const data = event.data;
	switch (data.request) {
		case "show":
			$("#scoreboard").show()
				.find("#scoreboard-territory").html(data.territory_name).end()
				.find("#scoreboard-status").html(data.territory_status).end()
				.find("#scoreboard-attackers_count").html(data.territory_attackers_count).end()
				.find("#scoreboard-defenders_count").html(data.territory_defenders_count);
			break;
		case "update":
			$("#scoreboard")
				.find("#scoreboard-status").html(data.territory_status).end()
				.find("#scoreboard-attackers_count").html(data.territory_attackers_count).end()
				.find("#scoreboard-defenders_count").html(data.territory_defenders_count);
			break;
		case "hide":
			$("#scoreboard").hide();
			break;
	}
});