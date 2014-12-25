mongoose    = require('mongoose')


userSchema  = mongoose.Schema {
    username:       String
    email:          {type: String, $p: {label: 'E-Mail'}}
    password:       {type: String, $p: {hide: true}}
    isAdmin:        {type: Boolean}
}

userSchema.virtual('$pTitle').get ()-> this.username
userSchema.virtual('$pTableRowClass').get ()-> if this.isAdmin then 'info' else null

User = mongoose.model('User', userSchema)

User.$p = {
    showAddButton: false
    showSearchForm: false
    redirectAfterAddEdit: 'old'
    rowActions: [
        {
            label:  'Articles'
            href: '/articles?conditions[user]={$row.id}'
        }
        {
            label:  'Pages'
            href: '/pages?conditions[user]={$row.id}'
        }
    ]
    pageActions: []
}

module.exports = User