mongoose	= require('mongoose')
penguin = require '../../'

schema = mongoose.Schema {
	title:		{type: String, required: true}
	published:	Boolean
	date:		{type: Date, required: true}
	content:	{type: String, required: true, $p: {widget: 'textarea', display: 'e'}}
	type:		{type: String, enum: ['p', 'a']}
	slug:		{type: String, $p: {hide: true}}
	user:		{type: mongoose.Schema.Types.ObjectId, ref: 'User', $p: {widget: 'select'}}
	cover:		{type: mongoose.Schema.Types.ObjectId, ref: 'File'}
	thumb:		{type: mongoose.Schema.Types.ObjectId, ref: 'File'}

}


Model = mongoose.model('Node', schema)

Model.$p = {
	hide: true
	actions: {
		publish: penguin.utils.createSimpleAction {published: true}
		unpublish: penguin.utils.createSimpleAction {published: false}
	}
	rowActions:  ['publish', 'unpublish']
	pageActions: ['_delete', 'publish', 'unpublish']
	setActions: ['_export_csv']
	sort: 'title'
	itemsPerPage: 50
}

module.exports = Model