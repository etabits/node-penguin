mongoose = require ('mongoose')
async = require 'async'

mongoose.connect('mongodb://localhost/penguin')


IDs = [mongoose.Types.ObjectId(), mongoose.Types.ObjectId()]
Seeds = {
	Node: [
		{type: 'p', user: IDs[0], title: 'About', content: 'We are simple the best, and the most humble, there is...'}
		{type: 'p', user: IDs[1], title: 'History', content: 'Since the big bang...'}
		{type: 'a', user: IDs[0], title: 'Welcome', content: 'Welcome to our new home...'}
	]
	User: [
		{_id: IDs[0], username: 'Master', email: 'master@example.org', password: 'plaintextpass', isAdmin: true}
		{_id: IDs[1], username: 'Peon', email: 'peon@example.org', password: 'usebcrypttostorepasswords!', isAdmin: false}
	]
}

for c in [1..100]
	Seeds.Node.push {
		type: 'a'
		user: IDs[0]
		title:"Article #{c}"
		content: "Content for article #{c}"
	}


#console.log mongoose.models
createSeeder = (modelName)-> (done)->
	model = mongoose.models[modelName]
	model.remove ()->
		model.create Seeds[modelName], (err)->
			console.log 'Inserted', arguments.length-1, modelName, 'documents for testing purposes.'
			done(err)


tasks = []
for modelName of Seeds
	require "./models/#{modelName.toLowerCase()}"
	tasks.push createSeeder(modelName)

async.parallel tasks, ()->
		mongoose.disconnect()


#Node.remove ()->
#	Node.create , (err)->