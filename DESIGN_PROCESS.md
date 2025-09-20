# Specification
The specification evolved throughout the designs.

1. Creator assists in the creation process of a database and it's underlying structure.
2. Due to the persistence of databases, memory-usage is of highest priority.
3. The data must be easily accessible.
4. The data must be easy to add to and remove from.
5. The data must be serializable.
6. Extensibility is a priority.

# Design Process

Each design will be formatted in such a manner:

## Design Number
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

## Design #1
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


## Design #2
<details>
<summary>Introduce the idea that future/past support is valuable.</summary>

### Reasoning
IsLoaded had no use internally and could be easily created w/ a wrapper.  The prior version did not have ways to support a migration path between versions.  Using an object-oriented approach to avoid passing the name of the store simplified the experience.

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
* `add(string, CreatorSettings)`: Adds contents to a store.
* `load(number)`
* `getSaveData(number)`
* `update(number)`
* `default(...)`: Sets up the default values
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
store:add("Foo", Creator.generateSettings(??))
store:load(12345)
local userData = store:getSaveData(12345)

```

### Comments
1. Add, now generateSettings, is still painful, so painful that it was avoided during the design process.
2. Maybe we can, when we create the Database, insert these Settings?
3. Update and default are still not required.

</details>


## Design #3
<details>
<summary>Simplify generating settings.</summary>

### Reasoning
How do we create Property?

What should the collection format be?

What can we get rid of?

### Design
`Creator.create(string, ...CreatorProperty): CreatorObject`: Removed to allow for Properties to attach themselves to the CreatorObject.

`Creator.create(string): CreatorObject`

`CreatorProperty.create(string): CreatorProperty`: Replaced to allow for Properties to attach themselves to the CreatorObject

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
<summary>CreatorCollection: Replaced by Collection</summary>

* `Defaults(...any)`
* `Variadic: boolean`
* `SaveAttributes(...string)`
* `generate(): CreatorGenerator`

</details>

<details>
<summary>CreatorGenerator: Replaced by CollectionGenerator</summary>

* `insert(string, string, {[string]: any}): CreatorGeneratorObject`: Takes in the Id, Name, and Attributes (removed for `Attributes({[string]: any})`)

</details>

<details>
<summary>CreatorGeneratorObject: Unused</summary>

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
<summary>CollectionGenerator: Replaces CreatorGenerator</summary>

* `insert(number, string)`: (id, name)
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
1. Property design is hard to follow, there are too many types and functions.  
2. The data design is non-existent.  How do we use the data?
3. Most of the settings or properties were seemingly removed, which is nice.
4. What if we re-add support for Variant (the ability to restrict and specify value types)?

</details>


## Design #4
<details>
<summary>Data accessibility</summary>

### Reasoning
From [499fb07](https://github.com/nwinn-student/luau-creator/blob/499fb07b0eb00175e8a6047c4bf428d917d72d1f/README.md) to [421a09c](https://github.com/nwinn-student/luau-creator/commit/421a09c8fc10f2a35af9e1d3554652da4c0fd669).  This design and a few of the following designs were created with intent to focus on the data accessibility aspect rather than the Collection painpoint.

### Design
`Creator.create(string): Creator`

`Creator.fromName(string): Creator`

<details>
<summary>MigrationFunction</summary>

* `(name: string, data: any) -> any`

</details>

<details>
<summary>Creator</summary>

* `Name: string`: The dataset name
* `SetProperty(self, name: string, property: Collection): Creator`
* `GetProperties(self): {[string]: Collection}`
* `load(self, id: string): CreatorObject`
* `migrate(self, MigrationFunction)`

</details>

<details>
<summary>CreatorObject</summary>

* `Name: string`: The name associated with the record, the primary key.
* `data(self): any`: Returns data associated with the record.
* `GetAttributes(self, position: string): {[string]: any}`: Returns the metadata associated with the record at a specified position.  A position is defined as key[.key], meaning that the metadata for data.key1.key2.etc is retrieved.
* `GetComponents(self, position: string): {[string]: any}`: From [27863a0](https://github.com/nwinn-student/luau-creator/blob/27863a0cfe109815068b2b91380a0d86499af899/README.md).   Returns the components associated with the record at a specified position.  A position is defined as key[.key], meaning that the components for data.key1.key2.etc are retrieved.
* `update(self)`: Updates the internal data associated with the record based on the external data provided using `data(self): any`, or the provided data.  The provided data is typically used when initially loading, as the migrator function is called to adjust the data to properly conform to the existing format.
* `fetch(self): buffer`: Returns a serialized form of the internal data.  The last call's return value is held until `update(self, data: any?)` is called to reduce potential overhead.

</details>

<details>
<summary>Collection: See [#3](#design-#3)</summary>

* `Variadic`: Additional Elements to the collection, unspecified in the initial collection, shall be added to the serialized output.
* `Defaults`: The default values associated with a CollectionElement's `Value` property, typically one value per type.  i.e. "", 0, vector.zero, etc.
* `SaveAttributes`: Determines which attributes of the Element to add to the serialized output.
* `RemoveDefaultAttributes`: Whether saved attributes will be filtered according to the set default values.

</details>

<details>
<summary>Element<Collection></summary>

* `Id`: The identifier of the Element used to allow for the Name of the element to change without needing to implement migration patterns.
* `Name`: The key of the Element within the dataset.
* `Value`: The value of the Element within the dataset.  
* `Attributes`: Properties associated with the Element.

</details>

### Example
```luau
	local store = Creator.create("Database")
	
	local store:SetProperty("Foo", {
		{Id=1,
			Name = "Baz"
		}
	})
	
	local userData = store:load("12345")
	local serialData = userData:fetch()
```

### Comments
1. Passing a table for the Collection is confusing and prone to error since at the time of this design there was little to no support for autocomplete w/ creating tables in functions.
2. SetProperty is confusing, it is expected to purely set the property and not return anything.
3. Data is flawed in that to obtain deep versions, `GetComponents("blah.ble")` is required, instead of being able to do `blah.ble`.

#### Minor Updates that don't quantify a new version
1. [7d770d4](https://github.com/nwinn-student/luau-creator/commit/7d770d4954b001ae8bea514a125b3747787732c5) modified Creator to become Database and CreatorObject to become DataRecord and MigrationFunction to become Migrator.
2. [421a09c](https://github.com/nwinn-student/luau-creator/commit/421a09c8fc10f2a35af9e1d3554652da4c0fd669) `update` now takes another parameter, for migration.

</details>


## Design #5
<details>
<summary>Removal of migration support</summary>

### Reasoning
Migration can be added back into the design at a later stage if needed. 

### Design
`Creator`: See [#4](#design-#4)

<details>
<summary>Database: See [#4](#design-#4)</summary>

* `SetProperty(name: string, property: Collection)`
* `GetProperty(name: string): Property`
* `withProperty(name: string, property: Collection): Database`
* `new(id: string): DataRecord`
* `load: nil`
* `migrate: nil`
</details>

<details>
<summary>DataRecord: See [#4](#design-#4)</summary>

* `data: nil`
* `GetData(): any`
* `load(data: any)`: Loads the provided data into the record.
* `update()`: Updates the internal data associated with the record based on the external data provided using data(self): any, or the provided data.

</details>

<details>
<summary>Collection: See [#4](#design-#4)</summary>
</details>

<details>
<summary>Element: See [#4](#design-#4)</summary>
</details>

### Example
```luau
	local store = Creator.create("Database")
	
	store:withProperty("Foo", {
		{Id=1,
			Name = "Baz"
		}
	})
	
	local userData = store:new("12345")
	local serialData = userData:fetch()
```

### Comments
1. See [#4](#design-#4), minus the second comment.

#### Minor Updates that don't quantify a new version
1. [2751292](https://github.com/nwinn-student/luau-creator/commit/2751292e87fa350eb9bc91769b3ae727458391fd) changed fetch to fetchRecord.
