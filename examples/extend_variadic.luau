local Creator = require("../src")

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

local builder = Creator.structBuilder

local recordMethods = builder():toStruct():newRecord().__index


-- Variadic
-- Record
--     withRecord(name: string)

local baseStruct = Creator.structBuilder():toStruct()

function recordMethods:withRecord(name: string)
	self[name] = baseStruct:newRecord()
	return self
end

print(Creator.structBuilder()
	:toStruct()
	:newRecord()
	:withRecord("hey")
	:record("hey"):withValue(1))

return Creator
