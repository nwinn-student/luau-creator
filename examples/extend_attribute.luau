local Creator = require("../src")

type Creator<
		T = unknown, R = unknown, S = unknown
	> = Creator.Creator<T, unknown, R, S>
type Builder<
		T = unknown, R = unknown, S = unknown
	> = Creator.StructBuilder<T, unknown, R, S>
type Record<T = unknown> = Creator.Record<T>

type Named<T> = {[string]: T}

type AttributeRecord = {
	attribute: (
		self: Record<AttributeRecord>,
		name: string
	) -> any,
	withAttribute: (
		self: Record<AttributeRecord>,
		name: string,
		value: any
	) -> Record<AttributeRecord>
}
type AttributeSimple = { read Attributes: Named<any> }
type AttributeBuilder = {
	withAttributes: (
		self: Builder<AttributeBuilder, AttributeRecord, AttributeSimple>, 
		attrs: Named<any>
	) -> Builder<AttributeBuilder, AttributeRecord, AttributeSimple>
}

type AttributeCreator = Creator<
	AttributeBuilder,
	AttributeRecord,
	AttributeSimple
>

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
