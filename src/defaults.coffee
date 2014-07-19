path = require 'path'


d = {}

d.opts = {
	modelsPath:		path.resolve(process.cwd(), 'models')
	mountPath:		'/admin'
	indexTitle:		'Penguin Geese Admin'
}
d.model$p = {
	fields: []
	conditions: {}
	hide: false
	fieldsToPopulate: []
}
d.model$pOverrides = {
	hide: false
}
d.field$p = {
	type: 'string'
	widget: 'text'
	hide: false
	display: 'le'	#list, edit
}
d.typesMap = { # constructor / widget
	String:		['string', 'text']
	Boolean:	['boolean', 'checkbox']
}

module.exports = d