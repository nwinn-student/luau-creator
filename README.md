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
local Creator = require("./Creator")

local Bar = {
	{Id=1,
		Name = 'Greeting'
	}
}

local Foo = Creator.create('Foo')
	:withProperty('Bar', Bar)

-- Sets up a dataset for User_12345
local userData = Foo:new('User_12345')

-- .. modifications to the data
userData.Bar.Greeting = 500

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
type Element<Collection> = {
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
	[number]: Element<Collection>,

	Variadic: boolean?,
	Defaults: {any}?,
	SaveAttributes: {string}?,
	RemoveDefaultAttributes: boolean?
}

-- The creator type used to define creator and its objects

type MetaRecord = {
	GetAttributes: (self: MetaRecord) -> {[string]: any},
	GetComponents: (self: MetaRecord) -> {[string]: MetaRecord},
}

-- The actual data within a database
type DataRecord = {
	-- Property
	[string]: MetaRecord,
	
	read Name: string,
	
	load: (self: DataRecord, data: buffer) -> (),
	update: (self: DataRecord) -> (),
	fetchRecord: (self: DataRecord) -> buffer
}

type Database = {
	read Name: string,
	
	withProperty: (self: Database, name: string, property: Collection) -> Database,
	SetProperty: (self: Database, name: string, property: Collection) -> (),
	GetProperty: (self: Database, name: string) -> Collection,
	GetProperties: (self: Database) -> {[string]: Collection},
	
	new: (self: Database, id: string) -> DataRecord,
}
```
</details>

`Creator.create(name: string): Database`: TODO.
`Creator.fromName(name: string): Database`: TODO.


**Database**
* **Name**: The database name
* `withProperty(self, name: string, property: Collection): Database`: TODO.
* `SetProperty(self, name: string, property: Collection)`: TODO.
* `GetProperty(self, name: string): Collection`: TODO.
* `GetProperties(self): {[string]: Collection}`: TODO.
* `new(self, id: string): DataRecord`: TODO.


**Collection**
* **Variadic**: Additional Elements to the collection, unspecified in the initial collection, shall be added to the serialized output.
* **Defaults**: The default values associated with a collection Element's `Value` property, typically one value per type.  i.e. "", 0, vector.zero, etc.
* **SaveAttributes**: Determines which attributes of the Element to add to the serialized output.
* **RemoveDefaultAttributes**: Whether saved attributes will be filtered according to the set default values.


**Element**
* **Id**: The identifier of the Element used to allow for the Name of the element to change without needing to implement migration patterns.
* **Name**: The key of the Element within the database.
* **Value**: The value of the Element within the database.  
* **Attributes**: Metadata associated with the Element that could be saved alongside the column's data.


**DataRecord**
* **Name**: The name associated with the record, the primary key.
* `load(self, data: any)`: Loads the provided data into the record.
* `GetAttributes(self, position: string): {[string]: any}`: Returns the metadata associated with the record at a specified position.  A position is defined as key[.key], meaning that the metadata for data.key1.key2.etc is retrieved.
* `GetComponents(self, position: string): {[string]: any}`: Returns the components associated with the record at a specified position.  A position is defined as key[.key], meaning that the components for data.key1.key2.etc are retrieved. TODO: Explain the purpose.
* `update(self)`: Updates the internal data associated with the record based on the external data provided using `data(self): any`, or the provided data.
* `fetchRecord(self): buffer`: Returns a serialized form of the internal data.  The last call's return value is held until `update(self)` is called to reduce potential overhead. TODO: Remove this sentence?
