$ ()->
	$('input[type="datetime"]').combodate({
			firstItem: 'name'
			maxYear: 2015
			minYear: 1940
			minuteStep: 1
			template:	'D-MM-YYYY @ HH : mm : ss'
			format:		'YYYY-MM-DDTHH:mm:ss'
		})
	#$("[data-toggle='switch']").wrap('<div class="switch" />').parent().bootstrapSwitch();
