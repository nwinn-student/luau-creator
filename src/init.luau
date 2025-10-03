--!strict
--!optimize 2

type Named<T> = {[string]: T}

export type SimpleRecord<T = unknown> = T & {
	[string]: SimpleRecord<T>,
	read Value: any
}

export type Record<T = unknown> = T & {
	withValue: (self: Record<T>, value: any) -> Record<T>,
	value: (self: Record<T>) -> any,
	record: (self: Record<T>, name: string) -> Record<T>
}

export type Struct<T = unknown, R = unknown, S = unknown> = T & {
	--- Create a new record based on the database
	newRecord: (self: Struct<T,R,S>) -> Record<R>,
	--- Returns the internal template of the record used to construct
	--- the database
	frozenTemplate: (self: Struct<T,R,S>) -> SimpleRecord<S>
}

export type StructBuilder<T = unknown, U = unknown, R = unknown, S = unknown> = T & {
	write __extend: Named<(true | "clone")?>,
	
	--- Create the blueprint for a record
	---
	--- @param name record's name
	---
	--- @return a StructBuilder for the created record
	templateRecord: (self: StructBuilder<T,U,R,S>, name: string) -> StructBuilder<T,U,R,S>,
	--- Build the blueprint for the record
	---
	--- @return the holding record's StructBuilder
	build: (self: StructBuilder<T,U,R,S>) -> StructBuilder<T,U,R,S>,
	
	withValue: (self: StructBuilder<T,U,R,S>, value: any) -> StructBuilder<T,U,R,S>,
	
	toStruct: (self: StructBuilder<T,U,R,S>) -> Struct<U,R,S>
}

export type Creator<T = unknown, U = unknown, R = unknown, S = unknown> = {
	structBuilder: () -> StructBuilder<T,U,R,S>
}

-- TODO: combine R, since it is expected to be multiple tables
-- or a table & unknown, which simplifies to the table
export type Userbase<T, R = Record> = setmetatable<
	T,
	{
		__index: R
	}
>

local Creator = {}
local Extendor = {
	Name = "HideFromStruct", -- Removes Name once toStruct is called
	Value = "CloneIfTable", -- Clones Value if it is a table, otherwise passes a reference!
	Parent = "HideFromRecord", -- Avoids adding the element when newRecord is called
	--Attributes = "clone", -- Clones the table when newRecord is called
	--Value = true, -- Value is referenced when newRecord is called
}

local StructBuilder = {}
StructBuilder.__index = StructBuilder
StructBuilder.__extend = Extendor

local Struct = {}
Struct.__index = Struct

local Record = {}
Record.__index = Record

function StructBuilder:templateRecord(name: string)
	local init = { Name = name, Parent = self }
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

local function hideElements(data: {[any]: any})
	for name, record in data do
		local extend = Extendor[name]
		
		if not extend then
			hideElements(record)
			table.freeze(record :: StructBuilder)
			continue
		end
		
		if extend == "HideFromStruct" then
			data[name] = nil
		end
	end 
end

function StructBuilder:toStruct()
	hideElements(self)	
	table.freeze(self :: StructBuilder)
	return setmetatable({Template = self}, Struct)
end

@native
local function deepCopy(data: {[any]: any})
	local copy = {}
	for key, value in data do
		local extend = Extendor[key]
		
		if not extend then
			copy[key] = deepCopy(value)
			continue
		end
		
		if extend == "HideFromRecord" then
			continue
		end
		
		copy[key] = 
			if extend == "clone"
				or (extend == "CloneIfTable"
					and type(value) == "table")
			then
				table.clone(value)
			else
				value
	end
	return setmetatable(copy, Record)
end

function Struct:newRecord()
	return deepCopy(self.Template)
end
function Struct:frozenTemplate()
	return self.Template
end

function Record:withValue(value: any)
	self.Value = value
	return self
end
function Record:value()
	return self.Value
end
function Record:record(name: string)
	return self[name]
end

function Creator.structBuilder()
	return setmetatable({}, StructBuilder) :: StructBuilder
end

return Creator :: Creator
