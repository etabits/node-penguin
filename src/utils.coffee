merge = require 'merge'

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

utils.createMongoQueryFromRequest = (req)->
	conditions = merge true, req.model.conditions, req.query.conditions

	if req.query.q
		rx = new RegExp(req.query.q, 'i')
		$orConditions = []
		for f in req.model.fields
			continue if 'String'!=f.instance
			#console.log f.instance, f.path
			continue if conditions[f.path]
			c = {}
			c[f.path] = rx
			$orConditions.push c
		if $orConditions.length
			conditions.$or = $orConditions

	mongoQuery = req.model.obj.find(conditions)
	if req.query.sort
		query = mongoQuery.sort(req.query.sort)
	else
		query = mongoQuery.sort(req.model.sort)
	mongoQuery

module.exports = utils