local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Attributes<T> = {[string]: T}

local builder = Creator.structBuilder

local builderMethods = builder().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Compress: Involves practical usages
--     Focuses on output size and NOT speed
-- StructBuilder
--     Add withId
--     toDatabase reformats the data to be much cheaper
--             1. {Id = {Value, Records...}}
--                 Easy-ish to implement, slow-ish
--                     ~20x cheaper output size than nothing
--            

builderMethods.__extend[1] = "RecordWhenTable"
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
	
	-- Very useful to know about!
	-- also rather expensive since it can create MANY functions
	record.StructFinder = function()
		return record
	end
	if not self.StructFinder then
		self.StructFinder = function()
			return self
		end
	end
	
	return record
end
function builderMethods:withValue(value: any)
	self[1] = value
	return self
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

recordMethods.withValue = builderMethods.withValue

function recordMethods:value()
	return self[1]
end
function recordMethods:record(name: string)
	local struct = self.StructFinder()
	
	return self[2][struct.Relation[name] or name]
end


print(Creator.structBuilder()
	:withValue(5)
	:templateRecord("Foo")
		:withId(1)
		:withValue(2)
		:templateRecord("Baz")
			:withValue(3)
		:build()
	:build()
	:toStruct()
	:newRecord():record("Foo"):record("Baz"):value())
