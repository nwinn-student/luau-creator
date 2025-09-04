# Creator

#### Table of Contents
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Technical Details](#technical-details)

## Purpose

Creator is a dataset generator intended for use to assist the setup of database- [TODO]

Essentially, Creator creates a [database](https://en.wikipedia.org/wiki/Database) and adds tables to the database as properties whose columns are specified by the elements within the property.[TODO]

### Requirements
[Luau 0.670+](https://github.com/luau-lang/luau/releases): As internal methods use @self to refer to each other.

### Usage Cases
A user needs to create a schema for a database[TODO]

## Example

More in-depth examples can be found in [examples](./examples).

```luau
local creator = require("./Creator")

type Collection = Creator.Collection

local Bar: Collection = {
	{Id=1,
		Name = "Greeting"
	}
}

local Foo = creator.create("Foo")
	:SetProperty("Bar", Bar)

-- Sets up a dataset for User_12345
local userData = Foo:load("User_12345")

-- .. modifications to the data
local data = userData:data()
data.Bar.Greeting = 500

userData:update() -- Necessary!

-- .. serialize the data to store it
local serialData = userData:fetch()

```

## Technical Details

The format used to serialize the dataset is located in [FORMAT.md](./FORMAT.md).

<details>
<summary>Types defined for use in Creator</summary>

```luau

-- The collection type used to define creator properties
type DataColumn<Collection> = {
	-- Primary key
	Id: number,
	
	Name: string,
	Value: any?,
	
	-- Metadata
	Attributes: {[string]: any}?,
	
	-- Foreign key
	Join: Collection?
}

type Collection = {
	Variadic: boolean?,
	Defaults: {any}?,
	SaveAttributes: {string}?,
	RemoveDefaultAttributes: boolean?,
	
	[number]: DataColumn<Collection>
}

-- The creator type used to define creator and its objects

-- The actual data within a database associated with a name
type DataRecord = {
	read Name: string,
	
	data: (self: DataRecord) -> any,
	GetAttributes: (self: DataRecord, position: string) -> {[string]: any},
	GetComponents: (self: DataRecord, position: string) -> {[string]: any},
	
	update: (self: DataRecord, data: any?) -> (),
	fetch: (self: DataRecord) -> buffer
}

type Migrator = (name: string, data: any) -> any

type Database = {
	read Name: string,
	
	SetProperty: (self: Database, name: string, property: DataProperty) -> Database,
	GetProperties: (self: Database) -> {[string]: DataProperty},
	
	load: (self: Database, id: string) -> DataRecord,
	
	migrate: (self: Database, fn: Migrator) -> ()
}
```
</details>

`Creator.create(name: string): Database`: TODO.
`Creator.fromName(name: string): Database`: TODO.


**Database**
* **Name**: The database name
* `SetProperty(self, name: string, property: Collection): Store`: TODO.
* `GetProperties(self): {[string]: Collection}`: TODO.
* `load(self, id: string): DataRecord`: TODO.
* `migrate(self, fn: Migrator)`: Sets the function called when `update(self, data: any?)` is called for a record to migrate data to the existing format if possible.

**Collection**
* **Variadic**: Additional DataColumns to the collection, unspecified in the initial collection, shall be added to the serialized output.
* **Defaults**: The default values associated with a collection DataColumn's `Value` property, typically one value per type.  i.e. "", 0, vector.zero, etc.
* **SaveAttributes**: Determines which attributes of the DataColumn to add to the serialized output.
* **RemoveDefaultAttributes**: Whether saved attributes will be filtered according to the set default values.


**DataColumn**
* **Id**: The identifier of the DataColumn used to allow for the Name of the element to change without needing to implement migration patterns.
* **Name**: The key of the DataColumn within the database.
* **Value**: The value of the DataColumn within the database.  
* **Attributes**: Metadata associated with the DataColumn that could be saved alongside the column's data.


**DataRecord**
* **Name**: The name associated with the record, the primary key.
* `data(self): any`: Returns data associated with the record.
* `GetAttributes(self, position: string): {[string]: any}`: Returns the metadata associated with the record at a specified position.  A position is defined as key[.key], meaning that the metadata for data.key1.key2.etc is retrieved.
* `GetComponents(self, position: string): {[string]: any}`: Returns the components associated with the record at a specified position.  A position is defined as key[.key], meaning that the components for data.key1.key2.etc are retrieved. TODO: Explain the purpose.
* `update(self, data: any?)`: Updates the internal data associated with the record based on the external data provided using `data(self): any`, or the provided data.  The provided data is typically used when initially loading, as the migrator function is called to adjust the data to properly conform to the existing format.
* `fetch(self): buffer`: Returns a serialized form of the internal data.  The last call's return value is held until `update(self, data: any?)` is called to reduce potential overhead. TODO: Remove this sentence?
