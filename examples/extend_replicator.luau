local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}
type Replicator = (value: any)->()

type ReplicatorRecord = {
	write __index: ReplicatorRecord,
	
	withValue: (self: ReplicatorRecord, value: any) -> ReplicatorRecord,
	value: (self: ReplicatorRecord) -> any,
	
	record: (self: ReplicatorRecord, name: string) -> ReplicatorRecord,
	withRecord: (self: ReplicatorRecord, name: string) -> ReplicatorRecord,
	
	onChange: (self: ReplicatorRecord, fn: Replicator) -> ReplicatorRecord
}

type ReplicatorStruct = {
	write __index: ReplicatorStruct,
	write Template: SimpleRecord,
	
	newRecord: (self: ReplicatorStruct) -> ReplicatorRecord,
	frozenTemplate: (self: ReplicatorStruct) -> SimpleRecord,
}

type ReplicatorStructBuilder = {
	write __index: ReplicatorStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: ReplicatorStructBuilder?,
	write Value: any?,
	
	templateRecord: (self: ReplicatorStructBuilder, name: string) -> ReplicatorStructBuilder,
	build: (self: ReplicatorStructBuilder) -> ReplicatorStructBuilder,
	
	withValue: (self: ReplicatorStructBuilder, value: any) -> ReplicatorStructBuilder,
	
	toStruct: (self: ReplicatorStructBuilder) -> ReplicatorStruct
}

type ReplicatorCreator = {
	structBuilder: () -> ReplicatorStructBuilder
}

local builder = Creator.structBuilder

local builderMethods = builder().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Replicator -- Pass changes around
-- 
-- Record
--     withValue now calls replicator function
--     Add onChanged((value: any)->())

local withValue = recordMethods.withValue

function recordMethods:withValue(value: any)
	local repl = self.Replicator
	if repl then
		repl(value)
	end
	return withValue(self, value)
end
function recordMethods:onChange(fn: Replicator)
	self.Replicator = fn
	return self
end

return Creator :: ReplicatorCreator
