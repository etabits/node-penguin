mongoose = require ('mongoose')

mongoose.connect('mongodb://localhost/penguin')
Node = require './models/node'

Node.remove ()->
	Node.create [
			{type: 'p', title: 'About', content: 'We are simple the best, and the most humble, there is...'}
			{type: 'p', title: 'History', content: 'Since the big bang...'}
			{type: 'a', title: 'Welcome', content: 'Welcome to our new home...'}
		], (err)->
			console.log 'Inserted', arguments.length-1, 'documents for testing purposes.'
			mongoose.disconnect()