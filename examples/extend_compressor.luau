local Creator = require("../src")

type Creator<T = unknown> = Creator.Creator<T>
type Builder<T = unknown> = Creator.StructBuilder<T>

type CompressorBuilder = {
	withId: (
		self: Builder<CompressorBuilder>,
		id: number
	) -> Builder<CompressorBuilder>
}
type CompressorCreator = Creator<CompressorBuilder>

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Compress: Involves practical usages
--     Focuses on output size and NOT speed
-- StructBuilder
--     Add withId
--     toDatabase reformats the data to be much cheaper
--       {Id = {Value, {Records...}}}
--       Records are in a separate table to not conflict
--         with outside extensions
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
	function record:StructFinder()
		return record
	end
	
	self[name] = nil
	self[2][name] = record
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

function structMethods:newRecord()
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
	local struct = self:StructFinder()
	local relation = struct.Relation
	return self[2][
		relation and relation[name]
			or name
	]
end

function Creator.structBuilder()
	local constructor = builder()
	
	function constructor:StructFinder()
		return constructor
	end
	
	return constructor
end

return Creator :: CompressorCreator
