mongoose	= require('mongoose')


userSchema  = mongoose.Schema {
	username:		String
	email:			String
	password:		{type: String, $p: {hide: true}}
	isAdmin:		{type: Boolean}
}

User = mongoose.model('User', userSchema)
module.exports = User