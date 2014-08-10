createAndSubmitForm = (fields, action='')->
	form = $('<form>', {
			action: action
			method: 'POST'
			class: 'hide'
		})
	for k, v of fields
		form.append $('<input>', {
				name: k
				value: v
				type: 'hidden'
			})
	form.appendTo('body').submit()

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
	$('table tr td button[data-action]').click ()->
		return unless confirm('Are you sure?')
		createAndSubmitForm {
			type: 'action'
			action: $(this).attr('data-action')
			ids: $(this).parents('tr').attr('data-id')
		}

	# Page Actions
	$('table thead tr th input[type="checkbox"]').change ()->
		$('table tr td input[type="checkbox"]').prop('checked', $(this).prop('checked')).change()
	$('table tbody tr td input[type="checkbox"]').change ()->
		if $(this).prop('checked')
			$(this).parents('tr').addClass('selected')
		else
			$(this).parents('tr').removeClass('selected')
	$('.page-actions button[data-action]').click ()->
		ids = $('table tbody tr td input[type="checkbox"]:checked').map ()->
			$(this).parents('tr').attr('data-id')
		return alert('No rows selected.') if not ids.length
		return unless confirm('Are you sure?')

		createAndSubmitForm {
			type: 'action'
			action: $(this).attr('data-action')
			ids: ids.get().join()
		}


	$('.set-actions button[data-action]').click ()->

		createAndSubmitForm {
			type: 'action'
			action: $(this).attr('data-action')
			scope: 'set'
		}

