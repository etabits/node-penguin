# Node Deps
path = require('path')

# Express'
express = require('express')

mongoose = require ('mongoose')


mongoose.connect('mongodb://localhost/penguin')





app = express()

developmentMode = app.get('env') == 'development'



# Setting up VIEWS
app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'jade');




if developmentMode
	app.use(require('less-middleware')(path.join(__dirname, 'public')))
	app.use(require('coffee-middleware')({src: __dirname + '/public'}))
	app.use(express.static(path.join(__dirname, 'public')))


if developmentMode
	app.use (err, req, res, next)->
		res.status(err.status || 500)
		res.render 'error', {
			message: err.message,
			error: err
		}	
		console.log(err)
		console.log(err.stack)
else # Production!
	app.use (err, req, res, next)->
		res.set('Content-Type', 'text/plain')
		res.send 500, 'Error'
		console.log 'ERROR', new Date(), err, err.stack



penguin = require '../'
admin = new penguin.Admin {
	indexTitle:		'Administration Home!'
	vModels: {
		pages: {
			base: 'nodes'
			conditions: {type: 'p'}
		}
		articles: {
			base: 'nodes'
			conditions: {type: 'a'}
		}
	}
}

admin.setupApp app

port = process.env.PORT || 3000
app.listen port, ()->
	console.log 'http://localhost:'+port+'/admin/'