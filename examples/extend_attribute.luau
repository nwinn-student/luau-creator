local Creator = require("../src")

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}

type AttributeRecord = {
	write __index: AttributeRecord,
	
	withValue: (self: AttributeRecord, value: any) -> AttributeRecord,
	value: (self: AttributeRecord) -> any,
	
	record: (self: AttributeRecord, name: string) -> AttributeRecord,
	
	attribute: (self: AttributeRecord, name: string) -> any,
	withAttribute: (self: AttributeRecord, name: string, value: any) -> AttributeRecord
}

type AttributeStruct = {
	write __index: AttributeStruct,
	write Template: SimpleRecord,
	
	newRecord: (self: AttributeStruct) -> AttributeRecord,
	frozenTemplate: (self: AttributeStruct) -> SimpleRecord,
}

type AttributeStructBuilder = {
	write __index: AttributeStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: AttributeStructBuilder?,
	write Value: any?,
	
	templateRecord: (self: AttributeStructBuilder, name: string) -> AttributeStructBuilder,
	build: (self: AttributeStructBuilder) -> AttributeStructBuilder,
	
	withValue: (self: AttributeStructBuilder, value: any) -> AttributeStructBuilder,
	
	toStruct: (self: AttributeStructBuilder) -> AttributeStruct
}

type AttributeCreator = {
	structBuilder: () -> AttributeStructBuilder
}

local builder = Creator.structBuilder

local builderMethods = builder().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Attribute
-- StructBuilder
--     Add withAttributes(Named<any>)
-- Record
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

return Creator :: AttributeCreator
