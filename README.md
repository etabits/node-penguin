node-penguin
============

Automatically generates administration pages based on your Mongoose models.

For basic use, you don't have to alter anything in your mongoose models definition, Penguin will read the definition and automagically create edit/add forms, in addition to a basic listing.

## Example
https://github.com/etabits/node-penguin-example

## Live example
Check [penguin.etabits.com/admin/](http://penguin.etabits.com/admin/).
*Temporarily offline!*

## Usage
In your app:
```javascript
app = express()
// ...

require('coffee-script/register') // <-- This dependency is to be removed very soon.
penguin = require('penguin')
admin = new penguin.Admin()
admin.setupApp(app)
```
This assumes that you have `./models` directory at the top level of your app.

The administration panel will mount at `/admin/` by default.

Check the `./example` directory for a complete example (Every feature is covered in the example).

## Features
* Custom actions: per row (`rowActions`), selected rows (`pageActions`), and current set (`setActions`).
* Automatic pagination of content
* Search inside text fields (quick filtering box)
* Support for referenced mongoose models ({type: ObjectId, ref: RemoteModel}, automatic .populate()...).
* Sorting by columns
* Add new documents, and edit existing ones
* Basic file upload manager
* Currently support basic field types (String, Date, ObjectId, Boolean).

## Minor Features
* Can set row class for table listing using the `$pTableRowClass` schema virtual.
* Can override default menu, use `menu` key to set your own links.
* Default sort, use `Model.$p.sort`.

## Roadmap
* Convert everything to plain javascript before publishing
* Deleting documents support
* Support for more fields
* More configurable parts
* Tests & Documentation!
