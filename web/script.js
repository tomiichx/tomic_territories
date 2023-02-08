console.log('debug')
window.addEventListener('message', function(event) {
	let data = event.data
	if (data.akcija == "pokazi") {
		$("#scoreboard").show()
		$("#ime-teritorije").html(data.ime_teritorije)
		$("#scoreboard-session").html('CAPTURING IN PROGRESS')
		$("#scoreboard-attack").html(data.broj_napadaca)
		$("#scoreboard-defend").html(data.broj_defendera)


	} else if (data.akcija == "sakrij") {
		$("#scoreboard").hide()
	}
});