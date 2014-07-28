mongoose	= require('mongoose')

schema = mongoose.Schema {
	title:		{type: String, required: true}
	date:		{type: Date, required: true}
	content:	{type: String, required: true, $p: {widget: 'textarea', display: 'e'}}
	type:		{type: String, enum: ['p', 'a']}
	slug:		{type: String, $p: {hide: true}}
	user:		{type: mongoose.Schema.Types.ObjectId, ref: 'User'}
	cover:		{type: mongoose.Schema.Types.ObjectId, ref: 'File'}
	thumb:		{type: mongoose.Schema.Types.ObjectId, ref: 'File'}

}


Model = mongoose.model('Node', schema)

Model.$p = {
	hide: true
}

module.exports = Model