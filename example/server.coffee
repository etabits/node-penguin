# Node Deps
path = require('path')

# Express'
express = require('express')

mongoose = require ('mongoose')

mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/penguin'
#console.log 'Connecting to ', mongoConnectionString
mongoose.connect mongoConnectionString





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
	# Defaults

	# The path to the directory containing the mongoose model files.
	# modelsPath:		path.resolve(process.cwd(), 'models')

	# The path at which the administration panel will be mounted. example.org/admin/
	# mountPath:		'/admin'

	fileManager: true

	# A title for the index page
	indexTitle:		'Administration Home!'

	# Virtual models
	vModels: {
		# /admin/pages
		pages: {
			# based on the `nodes` model
			base: 'nodes'
			# data is filtered using these conditions
			conditions: {type: 'p'}
		}
		articles: {
			base: 'nodes'
			conditions: {type: 'a'}
		}
	}

	# This marks areas where you can set your content.
	#defaultViewBlock: '<div class="text-center well well-sm">%s</div>'

	# extra html in the menu bar
	menuExtraHTML: '
		<ul class="nav navbar-nav navbar-right">
			<li>
				<a href="javascript:alert(\'Fake Logout link :)\')">Log Out</a>
			</li>
		</ul>'

	# Automatically built by default!
	menu: [
		[ 'Administration Home', '/admin' ]
		[ 'Sections', [
			#[ 'Files', '/admin/files' ]
			[ 'Articles', '/admin/articles' ]
			#[ 'Nodes', '/admin/nodes' ]
			[ 'Pages', '/admin/pages' ]
			[ 'Users', '/admin/users' ]
		] ]
	]

	uploadHandler: (req, res, next)->
		penguin.fileManager.save req.files.upload, (err, file)->
			res.send "<script type='text/javascript'>
			window.parent.CKEDITOR.tools.callFunction(#{req.query.CKEditorFuncNum}, '/#{file.path}', 'Success!');
			</script>"
			#console.log arguments



	# Called before any routing takes place, nothing is prepared, no parameters no .$p
	# Also intercepts statics
	# A good place to implement authentication
	preMiddleware: (req, res, next)->
		#return if -1 != req.headers['user-agent'].indexOf('Firefox') then next() else res.redirect '/'
		console.log 'Administration Request:', req.url, req.$p
		return next()


	# Called just before actual route invokation, req.$p is set here
	# A good place to implement authorization (per action/model/row...)
	beforeMiddleware: (req, res, next)->
		console.log 'beforeMiddleware', req.url, Object.keys(req.$p)
		res.$p.viewBlocks['layout.above_content'] = '<div class="clearfix">Welcome to <strong>Penguin</strong> Automated Administration Panel!</div>'
		return next()
}

# Want to add any static css/js?
admin.resLocals.statics.js.push('//cdn.ckeditor.com/4.4.4/standard/ckeditor.js')
admin.resLocals.statics.js.push('/admin/script.js')
admin.resLocals.statics.css.push('/admin/style.css')

admin.setupApp app

port = process.env.PORT || 3000
app.listen port, ()->
	console.log 'http://localhost:'+port+'/admin/'