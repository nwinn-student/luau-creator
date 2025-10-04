local Creator = require("../src")

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

require("./extend_attribute")
require("./extend_variadic")
require("./extend_migrator")
require("./extend_compressor")
require("./extend_replicator")

type Struct<T = unknown> = Creator.Struct<T>
type Record<T = unknown> = Creator.Record<T>
type Named<T> = {[string]: T}

type Replicator = (name: string, value: any)->()
type Migrator = (data: Record) -> Record

type AllSimple = {
	read Attributes: Named<any>?
}
type AllRecord = {
	attribute: (
		self: Record<AllRecord>,
		name: string
	) -> any,
	withAttribute: (
		self: Record<AllRecord>,
		name: string,
		value: any
	) -> Record<AllRecord>,
	
	withRecord: (
		self: Record<AllRecord>,
		name: string
	) -> Record<AllRecord>,
	
	withReplicator: (
		self: Record<AllRecord>,
		fn: Replicator
	) -> Record<AllRecord>
}
type AllStruct = {
	loadRecord: (
		self: Struct<AllStruct>,
		data: {[any]: any}
	) -> Record<AllRecord>,
	version: (self: Struct<AllStruct>) -> number,
}
type ABuilder<T> = Creator.StructBuilder<T, AllStruct, AllRecord, AllSimple>
type AllBuilder = {
	withAttributes: (
		self: ABuilder<AllBuilder>, 
		attrs: Named<any>
	) -> ABuilder<AllBuilder>,
	
	withVersion: (
		self: ABuilder<AllBuilder>,
		version: number
	) -> ABuilder<AllBuilder>,
	withMigrator: (
		self: ABuilder<AllBuilder>,
		fn: Migrator
	) -> ABuilder<AllBuilder>,
	
	withId: (
		self: ABuilder<AllBuilder>,
		id: number
	) -> ABuilder<AllBuilder>
}

type AllCreator = Creator.Creator<AllBuilder, AllStruct, AllRecord, AllSimple>

local structHolder = setmetatable({}, { __mode = "ks" })

function recordMethods:withRecord(name: string)
	local structFinder = function(self)
		return structHolder[self]
	end
	
	local record = setmetatable({
		StructFinder = structFinder
	}, recordMethods)
	
	structHolder[record] = {
		Parent = self:StructFinder()
	}
	
	if not self[2] then
		self[2] = {}
		-- No relation since we cannot specify the id
	end
	
	-- Call Replicator if exists?
	
	self[2][name] = record
	
	return self
end

-- withAttribute should call replicator if exists?
-- Attribute could be stored in a more optimal way, by not saving 
-- the word Attributes

local AllCreator: AllCreator = Creator

print(AllCreator:structBuilder()
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
		:withReplicator(function(name, value)
			print(value)
		end)
		:withValue(50)
		:record("what")
			:withReplicator(function(name, value)
				print(value)
			end)
			:withValue(1)
			:withRecord("how")
			:record("how")
				:withReplicator(function(name, value)
					print(value)
				end)
				:withValue(123))
	
-- locking down Creator
table.freeze(builderMethods)
table.freeze(structMethods)
table.freeze(recordMethods)

return Creator
