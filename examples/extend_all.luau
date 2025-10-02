local Creator = require("../src")

-- Incorrect, will fix later..
type Record = Creator.Record

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

require("./extend_attribute")
require("./extend_variadic")
require("./extend_replicator")
require("./extend_migrator")

-- Introducing this breaks record(name)
-- when working w/ withRecord(name)
-- also breaks withValue
local withValue = recordMethods.withValue
--local withRecord = recordMethods.withRecord

require("./extend_compressor")

function recordMethods:withValue(value: any)
	withValue(self, value) -- sets .Value
	self.Value = nil
	self[1] = value
	return self
end

local structHolder = setmetatable({}, { __mode = "ks" })

function recordMethods:withRecord(name: string)
	local record = {}
	
	local parent = self.StructFinder()
	
	local struct = {
		FullName = parent.FullName .. "." .. name,
		Parent = parent
	}
	
	structHolder[record] = struct
	
	record.StructFinder = function()
		return structHolder[record]
	end
	
	if not self[2] then
		self[2] = {}
		-- No relation since we cannot specify the id
	end
	
	self[2][name] = setmetatable(record, recordMethods)
	
	return self
end

print(Creator:structBuilder()
	-- From a performance perspective, this approach for
	-- replicator is not ideal at all
	:withReplicator(function(path: string, value: any)
		print(path, value)
	end)
	:withMigrator(function(data: Record)
		print(data)
	end)
	:templateRecord("hey")
		:withValue(5)
		:withId(8)
		:withAttributes({hey=1})
	:build()
	:toStruct()
	:newRecord()
		:withRecord("what")
		:withValue(50)
		:record("what")
			:withValue(1)
			:withRecord("how")
			:record("how")
				:withValue(123))
	
-- locking down Creator
table.freeze(builderMethods)
table.freeze(structMethods)
table.freeze(recordMethods)

return Creator
