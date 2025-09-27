--!strict
--!optimize 2

type Named<T> = {[string]: T}

export type SimpleRecord = {
	-- TODO: Allow for records to be supported by the type system
	[string]: Record,
	read Value: any,
}

export type Record = {
	write __index: Record,
	
	-- TODO: Allow for records to be supported by the type system
	[string]: Record,
	
	read withValue: (self: Record, value: any) -> Record,
	read value: (self: Record) -> any,
}

export type Struct = {
	write __index: Struct,
	write Template: SimpleRecord,
	
	--- Create a new record based on the database
	read newRecord: (self: Struct) -> Record,
	--- Returns the internal template of the record used to construct
	--- the database
	read frozenTemplate: (self: Struct) -> SimpleRecord
}

export type StructBuilder = {
	write __index: StructBuilder,
	-- Allows for extenders to have more control over the specifics
	write __extend: Named<(true | "clone")?>,
	write Parent: StructBuilder?,
	write Value: any?,
	
	--- Create the blueprint for a record
	---
	--- @param name the name associated with the record
	---
	--- @return a StructBuilder for the created record
	read templateRecord: (self: StructBuilder, name: string) -> StructBuilder,
	--- Build the blueprint for the record
	---
	--- @return the holding record's StructBuilder
	read build: (self: StructBuilder) -> StructBuilder,
	
	read withValue: (self: StructBuilder, value: any) -> StructBuilder,
	
	read toStruct: (self: StructBuilder) -> Struct
}

local Creator = {}
local Extendor = {}

local StructBuilder = {}
StructBuilder.__index = StructBuilder
StructBuilder.__extend = Extendor

local Struct = {}
Struct.__index = Struct

local Record = {}
Record.__index = Record

function StructBuilder:templateRecord(name: string)
	local init = { Parent = self }
	self[name] = init
	return setmetatable(init, StructBuilder)
end

function StructBuilder:build()
	return self.Parent or self
end

function StructBuilder:withValue(value: any)
	self.Value = value
	return self
end

function StructBuilder:toStruct()
	local function removeParent(data: {[any]: any})
		for name, record in data do
			if name == "Value" or Extendor[name] then
				continue
			end
			
			record.Parent = nil
			table.freeze(record :: StructBuilder)
			removeParent(record)
		end 
	end
	
	removeParent(self)
	
	table.freeze(self :: StructBuilder)
	
	return setmetatable({Template = self}, Struct)
end

@native
local function deepCopy(data: {[any]: any})
	local copy = {
		Value = data.Value
	}
	for key, value in data do
		if key == "Value" then
			continue
		end
		
		if Extendor[key] then
			copy[key] = if Extendor[key] == "clone" then
					table.clone(value)
				else
					value
			continue
		end
		
		copy[key] = deepCopy(value)
	end
	return setmetatable(copy, Record)
end

-- subject to alot of change when extending
function Struct:newRecord()
	return deepCopy(self.Template)
end

-- used for comparison
function Struct:frozenTemplate()
	return self.Template
end

-- commonly overridden
function Record:withValue(value: any)
	self.Value = value
	return self
end

-- slower, but ensures extenders can more easily modify
function Record:value()
	return self.Value
end

function Creator.structBuilder()
	return setmetatable({}, StructBuilder) :: StructBuilder
end

return Creator
