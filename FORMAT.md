
```luau
type Attribute = { [string]: any }
type Variadic = { [string]: Attribute }

-- If no children, attribute, or variadic, then Id: Value
type Element<Collection> = any | {
	any,		-- [1]
	Collection?,	-- [2]
	Attribute?, 	-- [3]
	Variadic? 	-- [4]
}

type Collection = {
	[number]: Element<Collection>
}

type Dataset = {
	[string]: Collection
}
```
