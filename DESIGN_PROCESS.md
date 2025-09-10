# Design Process

Each design will be formatted in such a manner:

## Design Name
<details>
<summary>A purpose, if any.</summary>

### Reasoning
A underlying reasoning or comments, if any.

### Design
`moduleName.functionName(paramType...): returnType`: Optional explanation.
<details>
<summary>typeName: Optional meaning.</summary>

* `functionName(paramType...): returnType`: Optional explanation.

</details>

### Example
```luau
	-- Example here to observe the beauty
	-- and observe pain points
```

### Comments
Written painpoints.

</details>


# Designs

## Initial
<details>
<summary>Rip apart an existing private project into a usable external component.</summary>

### Design
`Creator.Setup(string): boolean`: Creates a storage medium for the specified store, returning the success of creation.

`Creator.Add(string, {name: string, collection: {any}, position: (number | {number} | string | {string})?, index_to_save: (number | {number} | string | {string})?, allDefault: any?, collection_depth: number?, collection_position: ({number} | {string})?, attribute_name: (string | {string})?, attribute_position: (number | {number} | string | {string})?, override: boolean?, save_attribute: (string | {string})?, variadic: boolean?, removeDefaultAttribute: boolean?}): boolean`: Adds contents to a setup store from the provided collection using other properties to traverse the collection and infer various properties.

`Creator.InitializeDefaults(string, {any}): boolean`: Returns whether defaults were successfully initialized.

`Creator.LoadData(string, number, buffer?)`: Loads the data of the worker to the storage facility.

`Creator.IsLoaded(string, number): boolean`: Whether the worker's data has loaded into the storage facility.

`Creator.UpdateData(string, number)`: Updates the internal data of the worker to be consistent with the external data.

`Creator.GetSaveData(string, number): buffer`: Returns a processed version of the data associated with the worker


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
1. Needing to pass "Database" every time is painful.
2. Needing to know the layout of Add is painful.
3. IsLoaded and InitializeDefaults and UpdateData are not required for use and seem tacked on.

</details>


## Migration
<details>
<summary>Introduce the idea that future/past support is valuable.</summary>

### Design

`Creator.MigrateAttribute`: Removed

`Creator.MigrateIndex`: Removed

`Creator.MigrateForm`: Removed

`Creator.new(string): Store`

`Creator.add`: Removed

`Creator.load`: Removed

`Creator.getSaveData`: Removed

`Creator.update`: Removed

`Creator.default`: Removed

`Creator.generateSettings`

`Creator.create`: Removed**

<details>
<summary>Store</summary>

* `Name: string`: Name of the store
* `add(string, CreatorSettings)`
* `load(number)`
* `getSaveData(number)`
* `update(number)`
* `default(...)`
* `migrate.attribute(()->())`
* `migrate.index(()->())`
* `migrate.form(()->())`

</details>

<details>
<summary>CreatorSettings</summary>

* `create`: Removed in favor of generateSettings

</details>

### Example
```luau

local store = Creator.new("Database")
store:add("Foo", ??)
store:load(12345)
local userData = store:getSaveData(12345)

```

### Comments
1. Add, now generateSettings, is still painful, so painful that it was avoided during the design process.
2. Maybe we can, when we create the Database, insert these Settings?
3. Update and default are still not required.

</details>


## Phase 1 Exploration
<details>
<summary>Simplify generating settings.</summary>

### Reasoning
How do we create Property?

What should the collection format be?

What can we get rid of?

### Design
`Creator.create(string, ...CreatorProperty(???)): CreatorObject`

`CreatorProperty.create(string): CreatorProperty`: Replaced

`CreatorProperty.for(string, CreatorObject): CreatorProperty`

`CreatorProperty.create(string, CreatorObject)`: Same as `CreatorProperty.for`

<details>
<summary>CreatorObject</summary>

* `update(string)`
* `load(string)`
* `fetch(string): buffer`
* `read Name: string`
* `GetProperties(): {CreatorProperty}`
* `migrate((string, {})->({}), ...(string, {})->({}))`

</details>

<details>
<summary>CreatorProperty</summary>

* `read Name: string`
* `collection(): CreatorCollection`
* `read Parent: CreatorObject`

</details>

<details>
<summary>CreatorCollection</summary>

* `Defaults(...any)`
* `Variadic: boolean`
* `SaveAttributes(...string)`
* `generate(): CreatorGenerator`

</details>

<details>
<summary>CreatorGenerator</summary>

* `insert(string, string, {[string]: any}): CreatorGeneratorObject`: Takes in the Id, Name, and Attributes (removed for `Attributes({[string]: any})`)

</details>

<details>
<summary>CreatorGeneratorObject</summary>

* `Value: any`
* `Attributes({[string]: any})`
* `withValue(any): CreatorGeneratorObject`

</details>

<details>
<summary>Collection: Replaces CreatorCollection</summary>

<details>
<summary>Collection type</summary>

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

</details>

* `withVariadic(boolean?): Collection`
* `withDefaults({any}?): Collection`
* `withRemoveDefaults(...): ...`
* `withSaveAttributes(...): ...`
* `insert(string, string)`: Removed, (id, name)
* `toProperty`: Removed, you will see this later
* `generate(): CollectionGenerator`

</details>

<details>
<summary>CollectionGenerator: Also replaced</summary>

* `insert(string, string)`: (id, name)
* `toCollection(): Collection`

</details>


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
1. Property design is quite clunky.  
2. The data design is non-existent.
3. How do we use the data?
4. Most of the settings or properties were seemingly removed, which is nice.

NO to the below!
5. What if we re-add support for Variant?  It forces class to exist and it forces Defaults to be `{[string]: any}?`.  Issue is how to support new types?  We can always use typeof.  
Add Variant to collection, Variant also to element (why defaults is a tab).  No to element, Variant is used to specify a single type, if it is nil all types are supported. Only when class is clone! (??? what does this mean).

</details>
