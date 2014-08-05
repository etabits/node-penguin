utils = {}
utils.createSimpleAction = (updateDoc)->
	{
		apply: (conditions, context, done)->
			context.req.model.obj.update conditions, updateDoc, {multi: true}, done
		displaysFor: (row)->
			for field, val of updateDoc
				return true if val != row[field]
			return false
	}

module.exports = utils