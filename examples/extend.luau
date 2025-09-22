local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type DatabaseBuilder = Creator.DatabaseBuilder
type RecordBuilder = Creator.RecordBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord

local dbBuilder = Creator.databaseBuilder

local dbBuilderMethods = getmetatable(dbBuilder()).__index
local dbMethods = getmetatable(dbBuilder():toDatabase()).__index
local drMethods = getmetatable(dbBuilder():toDatabase():newRecord()).__index
local rbMethods = getmetatable(dbBuilder():toDatabase():newRecord():builder()).__index



-- Migrator -- Version control
-- DatabaseBuilder
--     Add withVersion(number) and withMigrator((data: DataRecord) -> DataRecord)
--     Add withId(number) -- for smaller output size
-- Database
--     Add loadRecord(buffer): DataRecord and version()
--     Add encodeRecord(DataRecord): buffer

function dbBuilderMethods:withVersion(version: number)
	self.Version = version
	return self
end

type Migrator = (data: DataRecord) -> DataRecord
function dbBuilderMethods:withMigrator(fn: Migrator)
	self.Migrator = fn
	return self
end

-- Optional: Helps encode produce smaller output size
--     but is painful to migrate
function dbBuilderMethods:withId(id: number)
	self.Id = id
	return self
end

function dbMethods:loadRecord(data: buffer)
	-- decode complexity depends on how dense you want the 
	-- buffer to be (how much preprocessing you did)
	return self.Migrator(decode(data))
end

function dbMethods:version()
	return self.Version
end

function dbMethods:encodeRecord(record: DataRecord): buffer
	-- encode complexity depends on how dense you want the 
	-- buffer to be (how much preprocessing to do)
	-- smaller output sizes may be a priority
	-- legibility may be priority [JSON]
	return encode(record)
end



-- Replicator -- Pass changes around
-- Could be wrong, it is rather complex and there is no implementation 
-- of Creator available to verify correctness.
--
-- DatabaseBuilder
--     Add withReplicator((path: string, value: any, isAttribute: boolean)->())
--     withAttributes now wraps the attr table in an object
-- Database
--     newRecord now passes an object referencing the data
--         instead of the data itself
-- DataRecord
--     Updated to use __newindex function ^
-- RecordBuilder
--     withValue now call Replicator when possible
--     withAttributes now wraps the attr table in an object

local function replicator(self, key: string, value: any)
	-- Replicator could be stored elsewhere
	local repl = self.Replicator
	if repl then
		repl(key, value, self.isAttr == true)
	end
	getmetatable(self).__index[key] = value
end

local newRecord = dbMethods.newRecord

function dbMethods:newRecord()
	-- MUCH harder to serialize
	return setmetatable({}, 
		{__index = newRecord(self), __newindex = replicator})
end

type Replicator = (path: string, value: any, isAttribute: boolean)->()
function dbBuilderMethods:withReplicator(fn: Replicator)
	self.Replicator = fn
	
	local attr = self.Attributes
	if attr then
		rawset(attr, "Replicator", fn)
	end
	
	return self
end

function dbBuilderMethods:withAttributes(data: {[string]: any})
	self.Attributes = setmetatable({Replicator = self.Replicator, isAttr = true}, 
		{__index = data, __newindex = replicator})
	return self
end

function rbMethods:withValue(value: any)
	local repl = self.Replicator
	if repl then
		repl("Value", value, false)
	end
	getmetatable(self).__index.Value = value
	return self
end

function rbMethods:withAttributes(data: {[string]: any})
	self.Attributes = setmetatable({Replicator = self.Replicator, isAttr = true}, 
		{__index = data, __newindex = replicator})
	return self
end

-- so replicator is flawed..
print(Creator.databaseBuilder()
	:templateRecord("Foo")
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
		:build()
	:build()
	:toDatabase()
	:newRecord()
		:builder()
			:withValue(4):toRecord().Value)
