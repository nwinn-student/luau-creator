# Creator

#### Table of Contents
- [Requirements](#requirements)
- [Example](#example)
- [Technical Details](#technical-details)

### Requirements
[Luau 0.670+](https://github.com/luau-lang/luau/releases): As internal methods use @self to refer to each other.

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
type Element<Collection> = {
	Id: number,
	Name: string,
	Value: any?,
	Attributes: {[string]: any}?,
	Collection: Collection
}

type Collection = {
	Variadic: boolean?,
	Defaults: {any}?,
	SaveAttributes: {string}?,
	RemoveDefaultAttributes: boolean?,
	
	[number]: Element<Collection>
}

-- The creator type used to define creator and its objects
type CreatorObject = {
	read Name: string,
	
	data: (self: CreatorObject) -> any,
	GetAttributes: (self: CreatorObject, position: string) -> {[string]: any}
	
	update: (self: CreatorObject) -> (),
	fetch: (self: CreatorObject) -> buffer
}

type MigrationFunction = (name: string, data: any) -> any

type Creator = {
	read Name: string,
	
	SetProperty: (self: Creator, name: string, property: Collection) -> Creator,
	GetProperties: (self: Creator) -> {[string]: Collection},
	
	load: (self: Creator, id: string): CreatorObject,
	migrate: (self: Creator, fn: MigrationFunction)
}
```
</details>

`Creator.create(name: string): Creator`: TODO.
`Creator.fromName(name: string): Creator`: TODO.


**Creator**
* **Name**: The dataset name
* `SetProperty(self, name: string, property: Collection): Creator`: TODO.
* `GetProperties(self): {[string]: Collection}`: TODO.
* `load(self, id: string): CreatorObject`: TODO.
* `migrate(self, fn: MigrationFunction)`: TODO.


**Collection**
* **Variadic**: Additional Elements to the collection, unspecified in the initial collection, shall be added to the serialized output. 
* **Defaults**: The default values associated with a CollectionElement's `Value` property, typically one value per type.  i.e. "", 0, vector.zero, etc.
* **SaveAttributes**: Determines which attributes of the Element to add to the serialized output.
* **RemoveDefaultAttributes**: Whether saved attributes will be filtered according to the set default values.


**Element<Collection>**
* **Id**: The identifier of the Element used to allow for the Name of the element to change without needing to implement migration patterns.
* **Name**: The key of the Element within the dataset.
* **Value**: The value of the Element within the dataset.  
* **Attributes**: Properties associated with the Element.


**CreatorObject**
* **Name**: TODO.
* `data(self): any`: TODO.
* `GetAttributes(self, position: string): {[string]: any}`: TODO.
* `update(self)`: TODO.
* `fetch(self): buffer`: TODO.

