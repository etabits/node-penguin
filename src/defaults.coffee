path = require 'path'


d = {}

d.opts = {
	modelsPath:		path.resolve(process.cwd(), 'models')
	mountPath:		'/admin'
	indexTitle:		'Penguin Geese Admin'
	fileManager:	false
	menuExtraHTML:  '<!-- inside menu -->'
}
d.model$p = {
	fields: []
	conditions: {}
	hide: false
	fieldsToPopulate: []
	actions: {}
	rowActions: []
	pageActions: ['_delete']
	setActions: []
	sort:		'-_id'
	itemsPerPage: 25
}
d.model$pOverrides = {
	hide: false
}
d.field$p = {
	type: 'string'
	widget: 'text'
	hide: false
	display: 'le'	#list, edit
	tasks: []
}
d.typesMap = { # constructor / widget
	String:		['string', 'text']
	Boolean:	['boolean', 'checkbox']
	Date:		['string', 'datetime']
}
d.res$p = {
	viewBlocks: {}
}
#d.resLocals = {}

module.exports = d