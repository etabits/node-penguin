fs = require 'fs'
path = require 'path'
qs = require 'qs'
packageJson = require('../package.json');
express = require 'express'
mongoose = require 'mongoose'
merge = require 'merge'
async = require 'async'
require 'mongoose-query-paginate'

forms = require('forms')
fields = forms.fields
validators = forms.validators
widgets = forms.widgets
merge widgets, require('./widgets')

fileManager = require './fileManager'
widgets.file = fileManager.widget

defaults = require './defaults'

commonActions = require './actions'
utils = require('./utils')

bodyParser = require('body-parser').urlencoded({ extended: false })

class Admin
	self = null
	debug = ()->

	## Instantiation
	constructor: (@opts={}) ->
		self = this
		@opts = merge(defaults.opts, @opts)
		@opts.staticsPath ?= "#{@opts.mountPath}/_statics"
		@opts.templatesPath ?= path.resolve(__dirname, '../views/', '%s.pug')
		debug = @opts.debug if @opts.debug
		@opts.beforeMiddleware ?= (req, res, next)-> next()
		console.log @opts
		self.models = {}
		self.modelDetails = {}
		self.resLocals = {
			mountPath: @opts.mountPath
		}
		self._readModels @opts.modelsPath, (err, models)->
			if self.opts.fileManager
				models['files'] = require './modelFile'
			#console.log models
			self.models = models
			for name, model of models
				#self.models[model.modelName] = model

				#continue if .dontInclude
				self.modelDetails[name] = self.getModelDetails {
					base: name
					slug: name
				}

			self.opts.vModels ?= {}
			for vt, vModel of self.opts.vModels
				model = self.models[vModel.base]
				vModel.slug ?= vt

				#console.log vt, vModel


				self.modelDetails[vModel.slug] = self.getModelDetails vModel
			if not self.opts.menu
				self.opts.menu = [
					['Administration Home', self.opts.mountPath]
					['Sections', []]
				]
				for modelName, model of self.modelDetails
					continue if model.hide
					self.opts.menu[1][1].push [model.label, "#{self.opts.mountPath}/#{model.slug}"]


			self.resLocals.models = self.modelDetails
			self.resLocals.menus = {
				main: self.opts.menu
			}
			self.resLocals.menuExtraHTML = self.opts.menuExtraHTML
			null
		#console.log packageJson
		if 'production'==process.env.NODE_ENV
			self.resLocals.statics = {
				css: [
					"#{@opts.staticsPath}/style.css?v=#{packageJson.version}"
				]
				js: [
					"#{@opts.staticsPath}/script.js?v=#{packageJson.version}"
				]
			}
		else
			self.resLocals.statics = {
				css: [
					"#{@opts.staticsPath}/css/10-bootstrap.css"
					"#{@opts.staticsPath}/css/20-flatui.css"
					"#{@opts.staticsPath}/css/50-penguin.css"
				]
				js: [
					"#{@opts.staticsPath}/js/10-jquery.js"
					"#{@opts.staticsPath}/js/20-bootstrap.js"
					"#{@opts.staticsPath}/js/30-moment.js"
					"#{@opts.staticsPath}/js/31-combodate.js"
					"#{@opts.staticsPath}/js/90-penguin.js"
				]
			}
		self

	_readModels: (path, done)->
		debug 'Reading models at %s, from %s', path, process.cwd()
		fs.readdir path, (err, files)->
			debug 'Got the following model files:', files
			models = {}
			for modelName, model of mongoose.models
				models[model.modelName] = model
				# allows for using the pluralized name
				models[model.collection.name] = model

			for f in files
				model = require "#{path}/#{f}"
				models[model.modelName] = model
				# allows for using the pluralized name
				models[model.collection.name] = model

			debug 'Models: obj', Object.keys(models)
			debug 'Models: mongoose', Object.keys(mongoose.models)
			
			return done(null, models)


	getModelDetails: (vModel)=>
		model = self.models[vModel.base]
		if not model
			console.error 'Could not find model for', vModel
			console.error 'We only have these models:', Object.keys(self.models)
		overrides = if vModel.slug == vModel.base then {} else defaults.model$pOverrides

		ret = merge true, defaults.model$p, model.$p, overrides, {
				label:	@constructor._t(vModel.slug)
				path:	"#{self.opts.mountPath}/#{vModel.slug}"
			}, vModel, {
				obj: model
			}
		ret.actions = merge true, commonActions, ret.actions

		#console.log vModel.slug, defaults.model$p, model.$p, defaults.model$pOverrides, vModel

		#console.log '>>>', defaults.vModel
		formFields = {}

		model.schema.eachPath (name, details)->
			return if '_' == name.substr(0, 1)
			return if 'undefined'!=typeof ret.conditions[name]
			fieldOpts = self.getDefaultFieldOpts(details)
			#console.log fieldOpts
			return if fieldOpts.hide
			details.$p = fieldOpts
			ret.fields.push(details)
			# Instantiate a new field
			details.$p.label ?= name
			formFieldOpts = merge {
				widget: widgets[fieldOpts.widget](fieldOpts.widgetOpts)
				$pField: details
				label: details.$p.label
			}, fieldOpts.formFieldOpts
			details.$p.formField = formFields[name] = fields[fieldOpts.type](formFieldOpts)

			if 'ObjectID' == details.instance && 'undefined' != typeof details.options.ref
				#console.log 'ref: ', vModel.base, name, '->', details.options.ref
				ret.fieldsToPopulate.push name
				if 'select' == details.$p.widget
					conditions = details.$p.refConditions || {}
					getSelectOptions = (done)->
						#console.log arguments
						fieldOpts.getRefModel().obj.find conditions, (err, docs)->
							listOptions = {}
							listOptions[doc._id] = doc.$pTitle for doc in docs
							formFields[name].choices = listOptions
							#console.log formFields[name]
							done()

					details.$p.tasks.push getSelectOptions
					#console.log details.$p.tasks


		ret.form = forms.create formFields
		ret

	getDefaultFieldOpts: (field)->
		def = merge true, defaults.field$p
		fieldOpts = merge true, field.options.$p
		#console.log field.options.type.name
		# if the `type` was not overriden in field opts, and we have a default type/widget for this field in our map
		if not fieldOpts.type && defaults.typesMap[field.options.type?.name]
			def.type = defaults.typesMap[field.options.type.name][0]
			def.widget = defaults.typesMap[field.options.type.name][1]

		if 'ObjectID' == field.instance
			fieldOpts.getRefModel = ()->
				referenceModel = self.models[field.options.ref] || mongoose.models[field.options.ref]
				if not referenceModel
					console.error 'no such referenced model "%s" @"%s". We only have:', field.options.ref, field.path, Object.keys(mongoose.models)
					return {}
				self.modelDetails[referenceModel.collection.name]
			# Automatically give the file widget for ref:File ObjectId fields
			if 'File' == field.options.ref
				fieldOpts.widget = 'file'

		merge true, def, fieldOpts


	setupApp: (app) =>
		@router = express.Router()
		self = this

		staticsPath = path.resolve(__dirname, '../statics')
		@router.use('/_statics', require('less-middleware')(staticsPath))
		@router.use('/_statics', require('coffee-middleware')({src: staticsPath}))
		@router.use('/_statics', express.static(staticsPath));

		@router.use (req, res, next)->
			for key, val of self.resLocals
				res.locals[key] = val
			next()
		@setupParams()
		@setupRoutes()

		#app.use @opts.mountPath, @mPrepareRequest
		app.use @opts.mountPath, @opts.preMiddleware if @opts.preMiddleware
		app.use @opts.mountPath, (req, res, next)->
			req.$p = {}
			res.$p = merge true, defaults.res$p
			next()

		app.use @opts.mountPath, @router
		app.locals.t = @constructor._t

	## Middlewares
	mPrepareRequest: (req, res, next)->
		switch req.$p.op
			when 'list', 'addform', 'add', 'edit', 'update' then # do nothing
			when 'action' then req.$p.action = req.body.action
			else debug('mPrepareRequest not handling op:', req.$p.op)

		#console.log req.params
		res.locals.getViewBlock = (blockName)-> res.$p.viewBlocks[blockName] || self.opts.defaultViewBlock.replace('%s', blockName)
		next()

	createRouteWrapper: (routeHandler, $p)->
		(req, res, next)->
			merge req.$p, $p
			# First we'll invoke the request preparing middleware
			self.mPrepareRequest req, res, ()->
				# Then we'll invoke the preMiddleware
					self.opts.beforeMiddleware req, res, ()->
						# now we'll invoke the handler itself!
						routeHandler(req, res, next)


	## PARAMETERS
	setupParams: =>
		@router.param 'collection', @pCollection
		@router.param 'id', @pId
			
			
		return

	pCollection: (req, res, next)->
		req.$p.model = self.modelDetails[req.params.collection]
		if 'undefined' == typeof req.$p.model
			return res.send(404)

		res.locals.model = req.$p.model
		return next()

	pId: (req, res, next)->
		return res.send(404) if not req.params.id.match /^[0-9a-f]{24}$/
		query = req.$p.model.obj.findById(req.params.id)
		query = query.populate req.$p.model.fieldsToPopulate.join(' ')
		query.exec (err, doc)->
			return next() if !doc

			# append resolved value of nested paths to original doc
			# so that we preserve virtual mongodoc fields as well
			for field in req.$p.model.fields
				doc[field.path] = utils.getFieldValueByPath(doc, field.path)
			req.$p.row = doc
			return next()
		return


	## ROUTES

	setupRoutes: =>
		@router.route('/')
			.get			@createRouteWrapper(@rIndex, {op: 'index'})							# INDEX


		
		postMiddlewares = []
		if true
			postMiddlewares.push @getMulterMiddleware()
			postMiddlewares.push fileManager.prepareFilesMiddleware
			@router.route('/_upload')
				.post 		@getMulterMiddleware(), @createRouteWrapper(@rUpload, {op: 'upload'})


		@router.route('/:collection')
			.get			@createRouteWrapper(@rCollection, {op: 'list'})						# LIST
			.post			bodyParser, @createRouteWrapper(@rCollectionPOST, {op: 'action'})	# Actions

		@router.route('/:collection/add')
			.get			@createRouteWrapper(@rEdit, {op: 'addform'})						# Add form
			.post			postMiddlewares, @createRouteWrapper(@rEdit, {op: 'add'})			# Add

		@router.route('/:collection/:id')
			.get			@createRouteWrapper(@rEdit, {op: 'edit'})							# EDIT
			.post			postMiddlewares, @createRouteWrapper(@rEdit, {op: 'update'})		# UPDATE
			#.delete			@rNotImplemented		# DELETE

	rUpload: (req, res, next)->
		self.opts.uploadHandler(req, res, next)


	rIndex: (req, res)=>
		self._render req, res, 'index', {title: @opts.indexTitle}
		#return res.send 'hello!'

	rCollectionPOST: (req, res, next)->
		if 'action' == req.body.type
			conditions = {}
			if req.body.scope == 'set'
				console.log 'N'
			else
				req.body.ids = req.body.ids.split(',')
				conditions._id = {$in: req.body.ids}

			action = req.$p.model.actions[req.body.action]
			return next() if not action
			action.apply conditions, {req: req, model: req.$p.model, res: res}, (err)->
				return next(err) if err
				# Chrome wouldn't interpret '' as a redirect to the same location
				res.redirect self.opts.mountPath + req.url

		else return next()
		#console.log req.body

	rCollection: (req, res)=>

		query = utils.createMongoQueryFromRequest(req)
		#console.log 'fieldsToPopulate', req.$p.model.fieldsToPopulate
		query = query.populate(req.$p.model.fieldsToPopulate.join(' '))

		paginationOptions = {
			perPage: req.$p.model.itemsPerPage
			delta  : 3
			page   : req.query.p
		}
		query.paginate paginationOptions, (err, result)->
			console.log('ERR', err) if err
			#console.log result.results

			docs = []
			for doc in result.results
				# append resolved value of nested paths to original doc
				# so that we preserve virtual mongodoc fields as well
				for field in req.$p.model.fields
					doc[field.path] = utils.getFieldValueByPath(doc, field.path)
				docs.push doc

			res.locals.getQueryString = (newObj)-> self._getQueryString(req, newObj)

			self._render req, res, 'collection', {
				docs:	docs
				title:	req.$p.model.label
				urlQuery:	req.query
				pagination: result
			}



	_rEditEmpty: (req, res)->
		console.log 'Form Empty'
		#console.log req.$p.row
		
		if req.$p.addMode
			req.$p.renderObj.form = req.$p.form
		else
			req.$p.renderObj.form = req.$p.form.bind(req.$p.row)
		self._render req, res, 'edit', req.$p.renderObj

	rEdit: (req, res)->
		#req.$p = {}
		req.$p.addMode = !req.$p.row
		res.locals.title = if req.$p.addMode then "Add #{res.locals.model.label}" else "#{req.$p.row.$pTitle || ''} - Editing"
		req.$p.form = req.$p.model.form
		#console.log form
		#console.log 'Row: ', req.$p.row
		req.$p.renderObj = {
			formOpts: {}
		}
		req.$p.renderObj.conditions = if 'object' == typeof req.query.conditions then req.query.conditions else {}
		console.log req.$p.renderObj
		tasks = []
		#console.log form.fields
		for field in req.$p.model.fields
			tasks = tasks.concat field.$p.tasks
		
		async.parallel tasks, ()->
			# An ugly hack, but apparently forms.create copy objects
			for field in req.$p.model.fields
				req.$p.form.fields[field.path].choices = field.$p.formField.choices if field.$p.formField.choices

			#console.log req.body
			if 'GET'==req.method
				self._rEditEmpty(req, res)
				return

			req.$p.form.handle req, {
				success: (nform)->
					console.log 'SUCCESS!'
					if req.$p.addMode
						req.$p.row = new req.$p.model.obj

					dataToSet = {}
					dataToSet[k]=v for k,v of nform.data

					# parse field values
					for field in req.$p.model.fields
						value = dataToSet[field.path]
						#console.log('widget.type',nform.fields[field.path].widget.type, value);
						# Just unset the '' file fields from the data to be set in the row
						if 'ObjectID' == field.instance && 'File' == field.options.ref && !value
							delete dataToSet[field.path]
						# unset datetime fields that are 'undefined' strings
						if 'datetime' == nform.fields[field.path].widget.type  && 'undefined' == value
							delete dataToSet[field.path]
						# convert stringified 'mixed' widget value back
						if 'mixed' == nform.fields[field.path].widget.type && nform.fields[field.path].widget.toValue
							dataToSet[field.path] = nform.fields[k].widget.toValue(value)

					# Also set the conditions as field values
					if req.$p.addMode
						dataToSet[k] = v for k, v of req.$p.model.conditions
						#return res.send 'WIP'

					# map value of flattened nested paths to mongo document
					for k,v of dataToSet
						utils.updateFieldValueByPath(req.$p.row, k, v)

					#return console.log '111',  nform.data, dataToSet, req.$p.row

					req.$p.row.save (err, doc)->
						#return console.log doc
						if err
							#console.log 'Error', err, err.errors
							req.$p.renderObj.form = nform
							if err.errors # Need to have a closer look at this...
								for fdName, error of err.errors
									req.$p.renderObj.form.fields[fdName].error = error.message
							else
								req.$p.renderObj.form.fields[err.path].error = err.message
							self._render req, res, 'edit', req.$p.renderObj
						else
							if req.flash && self.opts.flashMessagesIndex
								console.log 'Adding flash message'
								req.flash self.opts.flashMessagesIndex, {
									type: 'success'
									body: "#{req.$p.model.label.replace(/s$/, '')} saved successfully!"
								}
							if 'collection'==req.$p.model.redirectAfterAddEdit
								res.redirect './' + self._getQueryString(req)
							else
								res.redirect req.originalUrl


				error: (nform)->
					#console.log 'Form Error'
					req.$p.renderObj.form = nform
					self._render req, res, 'edit', req.$p.renderObj

				empty: ()->
					self._rEditEmpty(req, res)

			}

	rNotImplemented: (req, res)=>
		return res.send('Not Implemented')

	## MISC
	@_t: (str)->
		str.replace(/([a-z])([A-Z])/g, '$1 $2').replace /(?:^|_)[a-z]/g, (m) -> m.replace(/^_/, ' ').toUpperCase()

	_getQueryString: (req, newObj)->
		'?'+qs.stringify merge(true, req.query, newObj)


	_render: (req, res, template, locals) =>
		res.locals.templateName = template
		if req.flash && self.opts.flashMessagesIndex
			res.locals.flashMessages = req.flash(self.opts.flashMessagesIndex)

		res.render self.opts.templatesPath.replace('%s', template), locals

	getMulterMiddleware: ->
		if not self.multerMiddleware
			multer  = require('multer')
			self.multerUpload = multer {
				dest: './uploads/'
				includeEmptyFields: true
			}
			self.multerMiddleware = self.multerUpload.any()

		self.multerMiddleware



module.exports = {
	Admin: Admin
	utils: utils
	fileManager: fileManager
}
