mongoose    = require('mongoose')


userSchema  = mongoose.Schema {
    username:       String
    email:          {type: String, $p: {label: 'E-Mail'}}
    password:       {type: String, $p: {hide: true}}
    isAdmin:        {type: Boolean}
    tags: {type: Array, default: []}
    meta: {
        slug: {type: String}
        thumb: {type: String}
        settings: {type: mongoose.Schema.Types.Mixed}
        deepMeta: {
            deepSlug: String
        }
    }
    data: mongoose.Schema.Types.Mixed
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