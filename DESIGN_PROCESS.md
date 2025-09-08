# Design Process

Each design will be formatted in such a manner:

## Design Name
A purpose, if any.

### Design
* `moduleName.functionName(paramType...): returnType`: Optional explanation.
* `:typeName`: Optional meaning.
* 	`functionName(paramType...): returnType`: Optional explanation.

### Example
```luau
	-- Example here to observe the beauty
	-- and observe pain points
```

### Comments
Written painpoints.


## Initial
There are versions prior, however they contain private elements.

Compartmentalize an existing project by taking it apart and reducing as much complexity as possible for the project to extend, instead of having it built-in.

### Design
* `Creator.Setup(string): boolean`: Creates a storage medium for the specified store.  The store will hold the default folders and values specified in later methods, being duplicated for each player so that they can have their own storage medium.  Returns the success of creating a store.
* `Creator.Add(string, {name: string, collection: {any}, position: (number | {number} | string | {string})?, index_to_save: (number | {number} | string | {string})?, allDefault: any?, collection_depth: number?, collection_position: ({number} | {string})?, attribute_name: (string | {string})?, attribute_position: (number | {number} | string | {string})?, override: boolean?, save_attribute: (string | {string})?, variadic: boolean?, removeDefaultAttribute: boolean?}): boolean`: Creates contents within a store.  Returns the success of adding to a store.

			['name'] : type - string, mandatory
				the name of the folder to create within leaderstats
			['collection'] : type - table, mandatory
				the table containing the data to input into leaderstats, position 1 is ALWAYS the index, please
			['position'] : type - number or table, default is 2
				the position used as the name of the element within the table, one needed for each depth
			
			['index_to_save'] : type - number, default is 1
				the position used to hold the index within collection
					necessary if you plan to ever change the names of elements within collections and have it still save correctly
				
			['allDefault'] : type - variant, default is 0
				the default values for the contents of the folder
			['collection_depth'] : type - int, default is #position
				how deep to go into the array
			['collection_position'] : type - table, default is nil OR table of 3's with size collection_depth - 1
				what position within the table that holds other tables
			['attribute_name'] : type - string or table, default is nil
				a string or collection of strings that determine the name of the attibute
			['attribute_position'] : type - number or table, default is nil
				a number or collection of numbers that determine the position of the attribute value
			['save_attribute'] : type - string or table, default is {}
				a string or collection of strings that determine which attributes to save
				{[attr_name] = indexToSaveAs}, this allows for a much easier time when
				altering the save_attribute table
			['variadic'] : type - boolean, default is false
				a number or collection of numbers that determine whether to check 
				the instance for children and save all of the children
				Could lead to conflicts if a preset item is removed and the data is still kept
			['removeDefaultAttribute'] : type - boolean, default is false
				Does not save values that match allDefault.
				Could lead to conflicts if allDefault changes***
				
* `Creator.InitializeDefaults(string, {any}): boolean`: Returns whether defaults were successfully initialized.
* `Creator.LoadData(string, number, buffer?)`: Loads the data of the worker to the storage facility
* `Creator.IsLoaded(string, number): boolean`: Whether the worker's data has loaded into the storage facility
* `Creator.UpdateData(string, number)`: Updates the internal data of the worker to be consistent with the external data.
* `Creator.GetSaveData(string, number): buffer`: Returns a processed version of the data associated with the worker

### Example
```luau

Creator.Setup("Database")
Creator.Add("Database", {
	name = "Foo",
	collection = {
		{1, "Baz"}
	}
})
Creator.LoadData("Database", 12345)
local userData = Creator.GetSaveData("Database", 12345)

```

### Comments
From the example, needing to pass "Database" every time is incredibly painful.


## Migration
Realization of the importance of migration support within the API.

Various aspects seemed common, such as the need to migrate an attribute name from one name to another.

Mainly undocumented as it was quickly superceded by another design (baked into this design).

### Design
* `Creator.MigrateAttribute`: Removed
* `Creator.MigrateIndex`: Removed
* `Creator.MigrateForm`: Removed
* `Creator.new(string): Store`
* `Creator.add`: Removed
* `Creator.load`: Removed
* `Creator.getSaveData`: Removed
* `Creator.update`: Removed
* `Creator.default`: Removed
* `Creator.generateSettings`
* `Creator.create`: Removed**
* :Store
*	`Name: string`
*	`add(string, CreatorSettings)`
*	`load(number)`
*	`getSaveData(number)`
*	`update(number)`
*	`default(...)`
*	`migrate.attribute(()->())`
*	`migrate.index(()->())`
*	`migrate.form(()->())`
* :CreatorSettings
* 	`create`: Removed

### Example
```luau

local store = Creator.new("Database")
store:add("Foo", ??)
store:load(12345)
local userData = store:getSaveData(12345)

```

### Comments
GenerateSettings seems incredibly complex, and wasn't even designed due to the assumption of the complexity from looking at Initial's `Creator.Add`.

Maybe we can, when we create the Database, insert these Settings?


## Phase 1 Exploration
How do we create Property?

What should the collection format be?

What can we get rid of?

Yes, this is one design, you should see the later ones.

### Design
* `Creator.create(string, ...CreatorProperty(???)): CreatorObject`
* :CreatorObject
* 	`update(string)`
* 	`load(string)`
* 	`fetch(string): buffer`
* 	`read Name: string`
* 	`GetProperties(): {CreatorProperty}`
* 	`migrate((string, {})->({}), ...(string, {})->({}))`
* `CreatorProperty.create(string): CreatorProperty`: Replaced
* 	`default`: Within CreatorProperty, never got got shifted to CreatorCollection further down
* `CreatorProperty.for(string, CreatorObject): CreatorProperty`
* `CreatorProperty.create(string, CreatorObject)`: Same as `CreatorProperty.for`
* :CreatorProperty
* 	`read Name: string`
* 	`collection(): CreatorCollection`
* 	`read Parent: CreatorObject`
* :CreatorCollection
* 	`Defaults(...any)`
* 	`Variadic: boolean`
* 	`SaveAttributes(...string)`
* 	`generate(): CreatorGenerator`
* :CreatorGenerator
* 	`insert(string, string, {[string]: any}): CreatorGeneratorObject`: Takes in the Id, Name, and Attributes (removed for `Attributes({[string]: any})`)
* :CreatorGeneratorObject
* 	`Value: any`
* 	`Attributes({[string]: any})`
* 	`withValue(any): CreatorGeneratorObject`: The first introduction to with!
* :Collection Replaces CreatorCollection
```luau
{
	Variadic: boolean?, Defaults: {any}?, 
	
	-- Removed!!
	RemoveDefaults: "None" | "All" | "Attribute" | "Value",
	
	RemoveDefaultAttributes: boolean,
	SaveAttributes: {string},
	[number]: {
		-- value cannot be removed sadly
		Name: string, Value: any?, 
		Attributes: {[string]: any}?, 
		Id: number, -- Acts like a constant, expect 1 -> n
		Collection: Collection?
	}?
}
```
* 	`withVariadic(boolean?): Collection`
* 	`withDefaults({any}?): Collection`
* 	`withRemoveDefaults(...): ...`
* 	`withSaveAttributes(...): ...`
* 	`insert(string, string)`: Removed, (id, name)
* 	`toProperty`: Removed, you will see this later
* 	`generate(): CollectionGenerator`
* :CollectionGenerator Also replaced
* 	`insert(string, string)`: (id, name)
* 	`toCollection(): Collection`


### Example
```luau

local store = Creator.create("Database")

local Foo = CreatorProperty.create("Foo", store)
Foo:collection()
	:generate():insert(1, "Baz")

store:load("12345")
local userData = store:fetch("12345")

```

### Comments
The property design is quite clunky, but the data design is non-existent.  How do we use the data?  Most of the settings or properties were seemingly removed, which is nice.

NO to the below!
What if we re-add support for Variant?  It forces class to exist and it forces Defaults to be `{[string]: any}?`.  Issue is how to support new types?  We can always use typeof.  
Add Variant to collection, Variant also to element (why defaults is a tab).  No to element, Variant is used to specify a single type, if it is nil all types are supported. Only when class is clone! (??? what does this mean).
