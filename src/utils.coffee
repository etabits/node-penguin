merge = require 'merge'

utils = {}
utils.createSimpleAction = (updateDoc)->
	{
		apply: (conditions, context, done)->
			context.req.$p.model.obj.update conditions, updateDoc, {multi: true}, done
		displaysFor: (row)->
			for field, val of updateDoc
				return true if val != row[field]
			return false
	}

utils.createMongoQueryFromRequest = (req)->
	`const queryConditions = Object.fromEntries(
		Object.entries(req.query.conditions | {})
		.filter(([key,val])=>val!=='')
	)`
	conditions = merge true, req.$p.model.conditions, queryConditions

	if req.query.q
		rx = new RegExp(req.query.q, 'i')
		$orConditions = []
		for f in req.$p.model.fields
			continue if 'String'!=f.instance
			#console.log f.instance, f.path
			continue if conditions[f.path]
			c = {}
			c[f.path] = rx
			$orConditions.push c
		if $orConditions.length
			conditions.$or = $orConditions

	mongoQuery = req.$p.model.obj.find(conditions)
	if req.query.sort
		query = mongoQuery.sort(req.query.sort)
	else
		query = mongoQuery.sort(req.$p.model.sort)
	mongoQuery

utils.getFieldValueByPath = (doc, fieldPath)->
	return if !doc
	tokens = fieldPath.split('.')
	fieldValue = doc;
	for token in tokens
		if typeof fieldValue[token] == 'undefined' || fieldValue[token] == null
			fieldValue = fieldValue[token];
			break;
		fieldValue = fieldValue[token];
	return fieldValue

# Note: this function updates the field values in the doc directly
utils.updateFieldValueByPath = (doc, fieldPath, value)->
	tokens = fieldPath.split('.')
	if tokens.length <= 1
		# is not a flattened path, update value
		doc[fieldPath]=value
		return

	# only iterate up to n-1 token, because we can to hold the reference while updating it
	ref = doc
	lastToken = tokens[tokens.length-1]
	for token, i in tokens when i < tokens.length - 1
		ref = ref[token]
	# update value
	ref[lastToken]=value

module.exports = utils