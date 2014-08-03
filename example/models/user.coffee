mongoose	= require('mongoose')


userSchema  = mongoose.Schema {
	username:		String
	email:			String
	password:		{type: String, $p: {hide: true}}
	isAdmin:		{type: Boolean}
}

userSchema.virtual('$pTitle').get ()-> this.username
userSchema.virtual('$pTableRowClass').get ()-> if this.isAdmin then 'info' else null

User = mongoose.model('User', userSchema)
module.exports = User