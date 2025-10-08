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

type Struct<T = any> = Creator.Struct<T>
type Record<T = any> = Creator.Record<T>
type Named<T> = {[string]: T}

type Mode = "Attribute" | "Record"
type Replicator = (name: string, value: any, mode: Mode?)->()
type Migrator = (data: Record<AllRecord>) -> Record<AllRecord>

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
	-- what if we are reconstructing a record?
	-- should we infer "Sample", whose id is 1 to 
	-- automatically become 1?
	-- this allows us to use existing structfinder instead
	-- of making a new one

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
	
	local repl = self.Replicator
	if repl then
		repl(name, record, "Record")
	end
	
	self[2][name] = record
	
	return self
end

-- what if we have withId for attributes?
--		id is used to save bytes, attributes are often reused
--		and the cost is much less since they contain the same 
--      keys.  Id would, in BuffSer's case, decrease it from 3 -> 2 
--      bytes per key.  Assuming the ids are 1-128, and ordered,
--		even more bytes can be saved since the keys won't be saved.
--		Attributes are also often renamed, added/removed, so the 
--		frequency of such actions leads towards knowing the ids in 
--		order to migrate attributes properly.  Which is NOT what we 
--		want.
--		
-- what if we have a way to deduplicate?
-- 		deduplication is... painful, it has many edge cases
--		like: What if the value is a default, then the default is 
--		changed to the value, then a value is changed to a default, 
--		then the default is reverted?  Rip the value
--      like: should we do it internally or have a method
--      the method will recreate, but internally will avoid creating
--      as much as possible, only upon change (then recursively update
--		the record)
--		like: deduplicating does not guarantee a smaller or equal 
--		serialization size.  It guarantees a much smaller minimum, 
--		and guarantees a smaller size for data not using the Compressor
--		format.
--		like: we could format the deduplicating to be of smaller or 
--		equal, BUT it comes with performance tradeoffs
--		--
--		So all in all.  Deduplication is amazing, but is not worth the 
--		time to implement.  Especially if the intent is to pass the 
--		record to others who will use it frequently, not knowing about 
--		side effects when changing values to a default, not knowing 
--		the defaults.

function recordMethods:withAttribute(name: string, value: any)
	-- maybe we construct the attribute table??
	assert(type(self[3]) == "table", 
		"Unable to apply an attribute to a non-table value") -- ???
	
	local repl = self.Replicator
	if repl then
		repl(name, value, "Attribute")
	end
	
	self[3][name] = value
	return self
end

function recordMethods:attribute(name: string)
	if type(self[3]) ~= "table" then
		return nil
	end
	return self[3][name]
end

local function convertAttribute(data: Creator.Record)
	for name, value in data do
		if name ~= "Attributes" then
			if type(value) == "table" then
				convertAttribute(value)
			end
			continue
		end
		data[3] = value
		data.Attributes = nil
		continue
	end
end

local newRecord = structMethods.newRecord
function structMethods:newRecord()
	local record = newRecord(self)
	convertAttribute(record)
	return record
end

-- TODO: Fails to easily conform to extensions
-- Causes errors when using :StructFinder, meaning
-- we have to rewrite much more code to account for
-- this?

-- basically we need to just add structfinder.. that is all
local function wrap(data: {[any]: any}, par)
	local function addFinder(data, par)
		if par.StructFinder then
			data.StructFinder = par.StructFinder
		else
			local structFinder = function(self)
				return structHolder[self]
			end
			
			data.StructFinder = structFinder
			structHolder[data] = par
		end
	end
	--print(data, par)
	if type(data[2]) ~= "table" then
		addFinder(data, par)
		return setmetatable(data, recordMethods)
	end
	for key, value in data[2] do
		if type(value) ~= "table" then
			continue
		end
		
		local internalParent = par[key] or {
			Parent = par
		}
		
		wrap(value, internalParent)
	end
	addFinder(data, par)
	return setmetatable(data, recordMethods)
end

function structMethods:loadRecord(data: {[any]: any})
	local template = self.Template
	if not template.Migrator then
		return self:newRecord()
	end
	return template.Migrator(wrap(data, template))
end

local AllCreator: AllCreator = Creator
local format = AllCreator:structBuilder()
	:withMigrator(function(data)
		print(data)
		print(data:value())
		print(data:record("a"))
	end)
	:withVersion("v1.0.0")
	:templateRecord("hey")
		:withValue(5)
		:withId(8)
		:withAttributes({hey=1})
	:build()
	:toStruct()

local loaded = format:loadRecord({1,[2] = {
	a = {1,
	[2] = {1, b = {}}
	,[3] = 3}
},[3] = 3})
--print(format:newRecord())
--print(format:newRecord()
--		:withRecord("what")
--		:withReplicator(function(name, value, mode) 
--			print(value)
--		end)
--		:withValue(50)
--		:record("what")
--			:withReplicator(function(name, value, mode)
--				print(value)
--			end)
--			:withValue(1)
--			:withRecord("how")
--			:record("how")
--				:withReplicator(function(name, value, mode)
--					print(value)
--				end)
--				:withValue(123))
	
-- locking down Creator
--table.freeze(builderMethods)
--table.freeze(structMethods)
--table.freeze(recordMethods)

return Creator
