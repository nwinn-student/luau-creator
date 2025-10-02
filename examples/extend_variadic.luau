local Creator = require("../src")

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}

type VariadicRecord = {
	write __index: VariadicRecord,
	
	withValue: (self: VariadicRecord, value: any) -> VariadicRecord,
	value: (self: VariadicRecord) -> any,
	
	record: (self: VariadicRecord, name: string) -> VariadicRecord,
	withRecord: (self: VariadicRecord, name: string) -> VariadicRecord
}

type VariadicStruct = {
	write __index: VariadicStruct,
	write Template: SimpleRecord,
	
	newRecord: (self: VariadicStruct) -> VariadicRecord,
	frozenTemplate: (self: VariadicStruct) -> SimpleRecord,
}

type VariadicStructBuilder = {
	write __index: VariadicStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: VariadicStructBuilder?,
	write Value: any?,
	
	templateRecord: (self: VariadicStructBuilder, name: string) -> VariadicStructBuilder,
	build: (self: VariadicStructBuilder) -> VariadicStructBuilder,
	
	withValue: (self: VariadicStructBuilder, value: any) -> VariadicStructBuilder,
	
	toStruct: (self: VariadicStructBuilder) -> VariadicStruct
}

type VariadicCreator = {
	structBuilder: () -> VariadicStructBuilder
}

local builder = Creator.structBuilder

local recordMethods = builder():toStruct():newRecord().__index


-- Variadic
-- Record
--     withRecord(name: string)

local baseStruct = Creator.structBuilder():toStruct()

function recordMethods:withRecord(name: string)
	self[name] = baseStruct:newRecord()
	return self
end

return Creator :: VariadicCreator
