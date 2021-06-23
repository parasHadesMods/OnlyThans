ModUtil.RegisterMod("BarberPole")

local config = {
  ModName = "Only Thans",
  Enabled = true
}

if ModConfigMenu then
  ModConfigMenu.Register(config)
end

local biomeEncounters = {
  Tartarus = EncounterData.ThanatosTartarus,
  Asphodel = EncounterData.ThanatosAsphodel,
  Elysium = EncounterData.ThanatosElysium
}

ModUtil.WrapBaseFunction("ChooseEncounter", function(baseFunc, currentRun, room)
  local encounterData = nil
  for biome, encounter in pairs(biomeEncounters) do
    if room.RoomSetName == biome then
      encounterData = encounter
      break
    end
  end
  
  if encounterData ~= nil then
    local encounter = SetupEncounter(encounterData, room)

    return encounter
  else
    print("Can't force thanatos in " .. room.Name)
    return baseFunc(currentRun, currentRoom)
  end
end)
