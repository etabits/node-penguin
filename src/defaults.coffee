path = require 'path'


d = {}

d.opts = {
	modelsPath:		path.resolve(process.cwd(), 'models')
	mountPath:		'/admin'
}
d.vModel = {
	fields: []
	conditions: {}
}
d.field$p = {
	type: 'string'
	widget: 'text'
	hide: false
	display: 'le'	#list, edit
}

module.exports = d