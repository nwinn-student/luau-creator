local Creator = require("./Creator")

local Database = Creator.fromProperties(
	Creator.propertyBuilder("Store")
		:templateElement("Baz"):build()
		:templateElement("Foo"):build()
		:toProperty()
	):withVersion("v2.0.3")

-- v1.0.0 Code
--local Database = Creator.fromProperties(
--	Creator.propertyBuilder("Store")
--		:templateElement("Foo"):build()
--		:toProperty()
--	):withVersion("v1.0.0")

-- v1.6.5 Code
--local Database = Creator.fromProperties(
--	Creator.propertyBuilder("Store")
--		:templateElement("Baz"):build()
--		:toProperty()
--	):withVersion("v1.6.5")

local migrateTab = {
	--- v1.0.0 to v1.6.5 swapped Foo to Baz 
	['v1.0.0'] = function(data: Creator.DataRecord): Creator.DataRecord
		local Store = data.Store
		
		-- -- Alternative, creates new references to 
		-- --  Attributes and Elements and ensures
		-- --  all old references are removed
		--local Baz = Creator.createData()
		--	:withValue(Store.Foo.Value)
		--	:withAttributes(Store.Foo:GetAttributes())
		--	:withElements(Store.Foo:GetElements())
		--
		--Store.Baz = Baz
		--Store.Foo:Destroy()
		--Store.Foo = nil
		--
		--return data
		
		Store.Baz = Store.Foo
		Store.Foo = nil
		
		return data
	end,
	--- v1.6.5 to v2.0.3 re-added Foo
	['v1.6.5'] = function(data: Creator.DataRecord): Creator.DataRecord
		data.Store.Foo = Creator.createData()
		
		return data
	end,
}

--- Only v1.0.0 and v1.6.5 and v2.0.3
local function nextVersion(version: string): string
	return if version == "v1.0.0" then
			"v1.6.5"
		elseif version == "v1.6.5" then
			"v2.0.3"
		else -- no next
			"v2.0.3"
end

local function migrator(data: Creator.DataRecord): Creator.DataRecord
	
	-- Further verification may be necessary!
	-- not performed internally due to the nuances
	if data:GetVersion() == Database.Version then
		return data
	end
	
	local currVersion = data:GetVersion()
	
	repeat
		data = migrateTab[currVersion](data)
		currVersion = nextVersion(currVersion)
	until currVersion == Database.Version
	
	return data
end

-- Whenever Database:newRecord():load(...) is called, this too will be called
--  assuming ... is non-nil
Database:SetMigrator(migrator)

local userData = Database:newRecord()

-- Assume externaldata just returns a buffer of the old data (for now)
userData:load(require("./externaldata"))
