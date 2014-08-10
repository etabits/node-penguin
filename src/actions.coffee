actions = {}

actions._delete = {
	apply: (conditions, context, done)->
		context.model.obj.remove conditions, done
}

module.exports = actions