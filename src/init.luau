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
	-- TODO: Allow for value() to by supported by the type system
	
	--- 
	read withValue: (self: Record, value: any) -> Record,
	read value: (self: Record) -> any,
	
	read record: (self: Record, name: string) -> Record
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
	
	-- No guarantee!
	write Name: string?,
	write Value: any?,
	
	--- Create the blueprint for a record
	---
	--- @param name record's name
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
local Extendor = {
	-- Lets extenders avoid wrapping templateRecord in some cases
	Name = "HideFromStruct", -- Removes Name once toStruct is called
	Value = true, -- Value is referenced when newRecord is called
	Parent = "HideFromRecord", -- Avoids adding the element when newRecord is called
	--Attributes = "clone", -- Clones the table when newRecord is called
}

local StructBuilder = {}
StructBuilder.__index = StructBuilder
StructBuilder.__extend = Extendor

local Struct = {}
Struct.__index = Struct

local Record = {}
Record.__index = Record

-- Expected to be wrapped
function StructBuilder:templateRecord(name: string)
	local init = { Name = name, Parent = self }
	self[name] = init
	return setmetatable(init, StructBuilder)
end

-- Expected for no adjustments
function StructBuilder:build()
	return self.Parent or self
end

-- Expected to be overridden
function StructBuilder:withValue(value: any)
	self.Value = value
	return self
end

-- Expected for no adjustments
function StructBuilder:toStruct()
	local function hideElements(data: {[any]: any})
		for name, record in data do
			local extend = Extendor[name]
			if extend then
				if extend == "HideFromStruct" then
					data[name] = nil
				end
				continue
			end
			
			hideElements(record)
			table.freeze(record :: StructBuilder)
		end 
	end
	
	hideElements(self)	
	table.freeze(self :: StructBuilder)
	
	return setmetatable({Template = self}, Struct)
end

@native
local function deepCopy(data: {[any]: any})
	local copy = {}
	for key, value in data do
		local extend = Extendor[key]
		if extend then
			if extend == "HideFromRecord" then
				continue
			end
			copy[key] = if extend == "clone" then
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

-- slower, but ensures extenders can more easily modify
function Record:record(name: string)
	return self[name]
end

function Creator.structBuilder()
	return setmetatable({}, StructBuilder) :: StructBuilder
end

return Creator
