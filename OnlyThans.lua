ModUtil.RegisterMod("OnlyThans")

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

local previousBiome = nil

local specialRoomEnemySets = {
  A_MiniBoss01 = { "BloodlessGrenadierElite" },
  A_MiniBoss03 = { "WretchAssissinMiniboss" },
  A_MiniBoss04 = { "HeavyRangedSplitterMiniboss" },
  A_Boss01 = { "Harpy" },
  A_Boss02 = { "Harpy2" },
  A_Boss03 = { "Harpy3" },
  B_MiniBoss01 = { "HitAndRunUnitElite", "CrusherUnitElite" },
  B_MiniBoss02 = { "SpreadShotUnitMiniboss" },
  -- TODO: figure out B_Wrapping01
  B_Boss01 = { "HydraHeadImmortal", "HydraHeadImmortalLavamaker", "HydraHeadImmortalSlammer", "HydraHeadImmortalWavemaker" },
  C_MiniBoss01 = { "Minotaur" },
  C_MiniBoss02 = { "FlurrySpawnerElite", "ShadeNakedElite" },
  C_Boss01 = { "Minotaur", "Theseus" }
}

local specialRoomUnthreadedEvents = {
  A_Reprieve01 = { { FunctionName = "ActivateObjects", Args = { ObjectType = "HealthFountain" } } },
  B_Reprieve01 = { { FunctionName = "ActivateObjects", Args = { ObjectType = "HealthFountain" } } },
  C_Reprieve01 = { { FunctionName = "ActivateObjects", Args = { ObjectType = "HealthFountain" } } },
  A_Story01 = { { FunctionName = "ActivatePrePlaced" , Args = { FractionMin = 1.0, FractionMax = 1.0, LegalTypes = { "NPC_Sisyphus_01", "NPC_Bouldy_01" } } }, { FunctionName = "CheckConversations" } },
  B_Story01 = { { FunctionName = "ActivatePrePlaced" , Args = { FractionMin = 1.0, FractionMax = 1.0, LegalTypes = { "NPC_Euridice_01", "NPC_Orpheus_Story_01" } } }, { FunctionName = "CheckConversations" } },
  C_Story01 = { { FunctionName = "ActivatePrePlaced" , Args = { FractionMin = 1.0, FractionMax = 1.0, LegalTypes = { "NPC_Patroclus_01", "NPC_Achilles_Story_01" } } }, { FunctionName = "CheckConversations" } }
}

ModUtil.LoadOnce(function()
  EnemyData.Harpy.GeneratorData = { DifficultyRating = 500 }
  EnemyData.Harpy2.GeneratorData = { DifficultyRating = 500 }
  EnemyData.Harpy3.GeneratorData = { DifficultyRating = 500 }
  EnemyData.HydraHeadImmortal.GeneratorData = { DifficultyRating = 500 }
  EnemyData.HydraHeadImmortalLavamaker.GeneratorData = { DifficultyRating = 500 }
  EnemyData.HydraHeadImmortalSummoner.GeneratorData = { DifficultyRating = 500 }
  EnemyData.HydraHeadImmortalSlammer.GeneratorData = { DifficultyRating = 500 }
  EnemyData.HydraHeadImmortalWavemaker.GeneratorData = { DifficultyRating = 500 }
  EnemyData.Minotaur.GeneratorData = { DifficultyRating = 500 }
  EnemyData.Theseus.GeneratorData = { DifficultyRating = 500 }
  -- TODO: Make ThanatosStyx
end)

ModUtil.WrapBaseFunction("ChooseEncounter", function(baseFunc, currentRun, room)
  local encounterData = biomeEncounters[room.RoomSetName]
  if previousBiome == nil and CurrentRun and CurrentRun.CurrentRoom and CurrentRun.CurrentRoom.RoomSetName and biomeEncounters[CurrentRun.CurrentRoom.RoomSetName] then
    previousBiome = CurrentRun.CurrentRoom.RoomSetName
  end

  if encounterData ~= nil then
    previousBiome = room.RoomSetName
  else
    -- chaos, challenge rooms, etc use the biome they're in
    encounterData = biomeEncounters[previousBiome]
  end

  if encounterData ~= nil then
    encounterData = DeepCopyTable( encounterData )

    local specialRoomEnemySet = specialRoomEnemySets[room.Name]
    if specialRoomEnemySet then
      encounterData.EnemySet = specialRoomEnemySet
      encounterData.BlockHighlightEliteTypes = false
    end

    local specialRoomUnthreadedEvent = specialRoomUnthreadedEvents[room.Name]
    if specialRoomUnthreadedEvent then
      local unthreadedEvents = DeepCopyTable( specialRoomUnthreadedEvent )
      for _, event in pairs(encounterData.UnthreadedEvents) do
        table.insert( unthreadedEvents, event )
      end
      encounterData.UnthreadedEvents = unthreadedEvents
    end

    local encounter = SetupEncounter(encounterData, room)

    return encounter
  else
    print("Can't force thanatos in " .. room.Name)
    return baseFunc(currentRun, currentRoom)
  end
end)

local spawnPointOffset = nil
ModUtil.WrapBaseFunction("SelectSpawnPoint", function(baseFunc, currentRoom, enemy, encounter)
  local spawnPointId = baseFunc(currentRoom, enemy, encounter)

  if spawnPointId == nil then
    -- gotta put it somewhere
    spawnPointId = CurrentRun.Hero.ObjectId
    -- if we're doing this, increase the spawn radius
    spawnPointOffset = {
      X = RandomInt(-750, 750),
      Y = RandomInt(-750, 750)
    }
  end

  return spawnPointId
end)

ModUtil.WrapBaseFunction("SpawnUnit", function(baseFunc, args)
  if spawnPointOffset then
    args.OffsetX = spawnPointOffset.X
    args.OffsetY = spawnPointOffset.Y
    spawnPointOffset = nil
  end
  return baseFunc(args)
end)

ModUtil.WrapBaseFunction("SpawnRoomReward", function(baseFunc, eventSource, args)
  -- Don't spawn the default reward from C1
  -- It will spawn when you finish the Thanatos
  -- encounter instead
  if eventSource.Name == "RoomOpening" then
    return
  else
    baseFunc(eventSource, args)
  end
end)

ModUtil.WrapBaseFunction("MultiFuryIntro", function(baseFunc, ...)
  -- disable to prevent crashes
end)

