actions = {}
utils = require './utils'

actions._delete = {
    apply: (conditions, context, done)->
        context.model.obj.remove conditions, done
}

actions._export_csv = {
    apply: (conditions, context)->
        query = utils.createMongoQueryFromRequest(context.req)
        stream = query.stream()
        res = context.res
        fields = []
        for field in context.req.model.fields
            continue if (-1 == field.$p.display.indexOf('l'))
            fields.push(field.path)

        #console.log context.req.model
        filename = context.req.model.label + '-' + (new Date).toISOString().replace(/[\-:.TZ]/g, '')

        res.writeHead 200, {
            'Content-disposition':  "attachment; filename=#{filename}.csv"
            'Content-Type':         'text/csv'
        }

        res.write fields.join(',')+'\n'

        stream.on 'data', (row)->
            line = fields.map (fdName)->
                if row[fdName] then JSON.stringify(row[fdName]) else ''
            res.write line.join(',')+'\n'
        stream.on 'end', ()->
            res.end()
}

module.exports = actions