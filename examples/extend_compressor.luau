local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type DatabaseBuilder = Creator.DatabaseBuilder
type RecordBuilder = Creator.RecordBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord
type SimpleDataRecord = Creator.SimpleDataRecord

type Attributes<T> = {[string]: T}

local dbBuilder = Creator.databaseBuilder

local dbBuilderMethods = getmetatable(dbBuilder()).__index
local dbMethods = getmetatable(dbBuilder():toDatabase()).__index
local drMethods = getmetatable(dbBuilder():toDatabase():newRecord()).__index
local rbMethods = getmetatable(dbBuilder():toDatabase():newRecord():builder()).__index

-- Complex: Involves practical usages
--     Focuses on output size and NOT speed
--     Uses an approach similar to replicator, meaning it can 
--         easily be modified to support replicator
--     Could also easily be modified to restrict Value types
-- DatabaseBuilder
--     Add withId
--     toDatabase reformats the data to be much cheaper
--         There are multiple approaches:
--             1. {Id = {Value, Attributes, Records}}
--                 Easy-ish to implement, slow-ish
--                     ~20x cheaper output size than nothing
--             2. {Value..., Attributes..., Records...}
--                 Harder to implement, cheaper output size, 
--                     more memory intensive, slower
--                     ~20% cheaper than 1 on avg
-- Database
--     newRecord now passes a nearly unreadable record w/ 
--         a metatable to make it seem normal


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
			:withValue(4):toRecord())
