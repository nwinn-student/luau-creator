local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type DatabaseBuilder = Creator.DatabaseBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord
type SimpleDataRecord = Creator.SimpleDataRecord

type Named<T> = {[string]: T}
type Replicator = (path: string, value: any)->()

type ReplicatorDatabaseBuilder = {
	write __index: ReplicatorDatabaseBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: ReplicatorDatabaseBuilder?,
	write Value: any?,
	write Replicator: Replicator?,
	
	templateRecord: (self: ReplicatorDatabaseBuilder, name: string) -> ReplicatorDatabaseBuilder,
	build: (self: ReplicatorDatabaseBuilder) -> ReplicatorDatabaseBuilder,
	
	withValue: (self: ReplicatorDatabaseBuilder, value: any) -> ReplicatorDatabaseBuilder,
	withReplicator: (self: ReplicatorDatabaseBuilder, replicator: Replicator) -> ReplicatorDatabaseBuilder,
	
	toDatabase: (self: ReplicatorDatabaseBuilder) -> Database
}

type ReplicatorCreator = {
	databaseBuilder: () -> ReplicatorDatabaseBuilder
}

local dbBuilder: ReplicatorCreator = Creator.databaseBuilder

local dbBuilderMethods = dbBuilder().__index
local dbMethods = dbBuilder():toDatabase().__index
local drMethods = dbBuilder():toDatabase():newRecord().__index

-- Replicator -- Pass changes around
-- Could be wrong, it is rather complex and there is no implementation 
-- of Creator available to verify correctness.
--
-- DatabaseBuilder
--     Add withReplicator((path: string, value: any)->())
-- Database
--     newRecord now passes an object referencing the data
--         instead of the data itself
-- DataRecord
--     Updated to use __newindex function ^
dbBuilderMethods.__extend.Replicator = true
local function replicator(self, key: string, value: any)
	local repl = self.Replicator
	if repl then
		repl(key, value)
	end
	getmetatable(self).__index[key] = value
end

local newRecord = dbMethods.newRecord

function dbMethods:newRecord()
	-- MUCH harder to serialize
	return setmetatable({}, 
		{__index = newRecord(self), __newindex = replicator})
end

function dbBuilderMethods:withReplicator(fn: Replicator)
	self.Replicator = fn
	return self
end

local Replicator: ReplicatorCreator = Creator

-- NOT WORKING YET
local a = Replicator.databaseBuilder()
	:withReplicator(function(path: string, value) 
		print(path, value)
	end)
	:templateRecord("Foo")
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
		:build()
	:build()
	:toDatabase()
	:newRecord()

-- if we don't do :toRecord, the value we could have
-- stored elsewhere would become invalid upon use
-- meaning that we could set data to become Builder and use it 
-- like a Record since we assume the value stored was a Record

print(a.Value)
print(getmetatable(a))
