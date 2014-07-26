mongoose	= require('mongoose')

schema = mongoose.Schema {
	name: 			String
	originalName:	String
	path:			String
	extension:		String
	mimeType:		String
	size:			Number
	source: {
		model: String
		field: String
	}
}
schema.virtual('$pTitle').get ()-> this.originalName



Model = mongoose.model('File', schema)

module.exports = Model