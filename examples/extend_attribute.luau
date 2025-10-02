local Creator = require("../src")

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

local builder = Creator.structBuilder

local builderMethods = builder().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Attribute
-- StructBuilder
--     Add withAttributes(Named<any>)
-- Struct
--     Add attribute(string), withAttribute(string, any)

builderMethods.__extend.Attributes = "clone"

function builderMethods:withAttributes(attrs: Named<any>)
	self.Attributes = attrs
	return self
end

function recordMethods:attribute(name: string)
	if not self.Attributes then
		return nil
	end
	return self.Attributes[name]
end

function recordMethods:withAttribute(name: string, value: any)
	assert(self.Attributes, "Unable to set attribute") -- ???
	self.Attributes[name] = value
	return self
end

local Attribute: AttributeCreator = Creator

print(Attribute.structBuilder()
	:templateRecord("Foo")
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
			:withAttributes({Bar = 1})
		:build()
	:build()
	:toStruct()
	:newRecord())

return Attribute
