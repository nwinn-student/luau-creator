local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}

type CompressorStructBuilder = {
	write __index: CompressorStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: CompressorStructBuilder?,
	write Value: any?,
	
	templateRecord: (self: CompressorStructBuilder, name: string) -> CompressorStructBuilder,
	build: (self: CompressorStructBuilder) -> CompressorStructBuilder,
	
	withValue: (self: CompressorStructBuilder, value: any) -> CompressorStructBuilder,
	withId: (self: CompressorStructBuilder, id: number) -> CompressorStructBuilder,
	
	toStruct: (self: CompressorStructBuilder) -> Struct
}

type CompressorCreator = {
	structBuilder: () -> CompressorStructBuilder
}

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Compress: Involves practical usages
--     Focuses on output size and NOT speed
-- StructBuilder
--     Add withId
--     toDatabase reformats the data to be much cheaper
--       1. {Id = {Value, {Records...}}}
--         Easy-ish to implement, slow-ish
--           ~20x cheaper output size than nothing
--         Records are in a separate table to not conflict
--           with outside extensions
--            

builderMethods.__extend.Id = "HideFromRecord"
builderMethods.__extend.StructFinder = true
builderMethods.__extend.Relation = "HideFromRecord"


local templateRecord = builderMethods.templateRecord

function builderMethods:templateRecord(name: string)
	if not self[2] then
		self[2] = {}
		self.Relation = {}
	end
	
	local record = templateRecord(self, name)
	
	self[name] = nil
	self[2][name] = record
	
	-- could be stored outside, but adds complexity
	record.StructFinder = function()
		return record
	end
	
	return record
end
function builderMethods:withId(id: number)
	self.Id = id
	if not self.Parent then
		return self
	end
	
	local records = self.Parent[2]
	records[self.Name] = nil
	records[id] = self
	self.Parent.Relation[self.Name] = id
	return self
end

local newRecord = structMethods.newRecord

function structMethods:newRecord()
	local function convertValue(data: Record)
		for name, value in data do
			if name == "Value" then
				data[1] = value
				data.Value = nil
				continue
			end
			if type(value) == "table" then
				convertValue(value)
			end
		end
	end
	
	local record = newRecord(self)
	
	convertValue(record)
	
	return record
end

function recordMethods:value()
	return self[1]
end
function recordMethods:withValue(value: any)
	self[1] = value
	return self
end
function recordMethods:record(name: string)
	local struct = self.StructFinder()
	
	return self[2][struct.Relation[name] or name]
end

function Creator.structBuilder()
	local constructor = builder()
	
	constructor.StructFinder = function()
		return constructor
	end
	
	return constructor
end

local Compressor: CompressorCreator = Creator

print(Compressor.structBuilder()
	:withValue(5)
	:templateRecord("Foo")
		:withId(1)
		:withValue(2)
		:templateRecord("Baz")
			:withValue(3)
		:build()
	:build()
	:toStruct()
	:newRecord())--:record("Foo"))--:record("Baz"):value())

return Compressor
