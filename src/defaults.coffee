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

module.exports = d