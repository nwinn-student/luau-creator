
```luau
type Attribute = { [string]: any }

type Element<Collection> = {
	any,		-- [1]
	Collection?,	-- [2]
	Attribute?, 	-- [3]
}

type Collection = {
	[string]: Element<Collection>
}

type Dataset = {
	[string]: Collection
}
```
