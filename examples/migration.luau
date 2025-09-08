local Creator = require("./Creator")

local Database = Creator.fromProperties(
	Creator.propertyBuilder("Store")
		:templateElement("Baz"):build()
		:toProperty()
	)


-- Assume we had a prior version that had "Baz" as "Foo"

local function migrator(data: Creator.DataRecord): DataRecord
	
	-- We need to first determine the version in actual usage cases!
	
	local Store = data.Store
	
	-- This code is provided since there are multiple ways to do the same thing
	--  the design is subject to change
	--local Baz = Creator.createData()
	--	:withValue(Store.Foo.Value)
	--	:withAttributes(Store.Foo:GetAttributes())
	--	:withElements(Store.Foo:GetElements())
	
	Store.Baz = Store.Foo
	Store.Foo = nil
	
	return data
end

-- Whenever Database:newRecord():load(...) is called, this too will be called
--  assuming ... is non-nil
Database:SetMigrator(migrator)

local userData = Database:newRecord()

 -- Assume externaldata just returns a buffer of the old data (for now)
userData:load(require("./externaldata"))