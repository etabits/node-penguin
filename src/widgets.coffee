widgets = {}
`
function htmlNode(tag, attribs) {
	html = '<' + tag
	Object.entries(attribs)
	.filter(([attr, val])=> typeof val !== 'undefined')
	.forEach(([attr, val])=> {
		html += ' ' + attr + '="' + val +'"'
	})
	html += '/>'
	return html
}
`

dateTimeToHTML = (name, f)->
	value = f.value
	if f.value instanceof Date
		value = f.value.toISOString().substr(0, 19)
	htmlNode('input', {
		type: this.type,
		id: "id_#{name}",
		name: name,
		value: value,
		'data-template': f.$pField.$p.widgetTemplate
	})

textToHTML = (name, f)->
	if !f.value
		return "<input type=\"#{this.type}\" placeholder='Empty string' id=\"id_#{name}\" name=\"#{name}\" />"
	value = f.value
	return "<input type=\"#{this.type}\" id=\"id_#{name}\" name=\"#{name}\" value='#{value}' />"

mixedToHTML = (name, f)->
	# Note: the rendered HTML for this widget is overridden in form.jade eventually
	if !f.value
		return "<textarea id=\"id_#{name}\" name=\"#{name}\"></textarea>"

	# stringify 'mixed' widget value
	value = JSON.stringify(f.value)
	return "<textarea class='classic-textarea' id=\"id_#{name}\" name=\"#{name}\">#{value}</textarea>"

stringifiedToMixed = (str)->
	try
		return JSON.parse(str)
	catch
		val = parseFloat(str)
		return if !isNaN val
		return true if str.toLowerCase() == 'true'
		return false if str.toLowerCase() == 'false'
		# if we can't parse it into an object/float/int/bool, just return it back as a str
		# and let mongodb try to save it since its a Mixed type
		return str

widgets.datetime =  (opt={})->
	{ classes: opt.classes, type: 'datetime', toHTML: dateTimeToHTML }

widgets.text =  (opt={})->
	{ classes: opt.classes, type: 'text', toHTML: textToHTML }

widgets.mixed =  (opt={})->
	{ classes: opt.classes, type: 'mixed', toHTML: mixedToHTML, toValue: stringifiedToMixed }

module.exports = widgets