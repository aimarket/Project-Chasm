module GameData
  class TerrainTag
	attr_reader :slows
  
	def initialize(hash)
      @id                     = hash[:id]
      @id_number              = hash[:id_number]
      @real_name              = hash[:id].to_s                || "Unnamed"
      @can_surf               = hash[:can_surf]               || false
      @waterfall              = hash[:waterfall]              || false
      @waterfall_crest        = hash[:waterfall_crest]        || false
      @can_fish               = hash[:can_fish]               || false
      @can_dive               = hash[:can_dive]               || false
      @deep_bush              = hash[:deep_bush]              || false
      @shows_grass_rustle     = hash[:shows_grass_rustle]     || false
      @land_wild_encounters   = hash[:land_wild_encounters]   || false
      @double_wild_encounters = hash[:double_wild_encounters] || false
      @battle_environment     = hash[:battle_environment]
      @ledge                  = hash[:ledge]                  || false
      @ice                    = hash[:ice]                    || false
      @bridge                 = hash[:bridge]                 || false
      @shows_reflections      = hash[:shows_reflections]      || false
      @must_walk              = hash[:must_walk]              || false
      @ignore_passability     = hash[:ignore_passability]     || false
	  @slows     			  = hash[:slows]     			  || false
    end
  end
end

class PokemonEncounters
  # Returns whether the player's current location allows wild encounters to
  # trigger upon taking a step.
  def encounter_possible_here?
    return true if $PokemonGlobal.surfing
    terrain_tag = $game_map.terrain_tag($game_player.x, $game_player.y)
    return false if terrain_tag.ice
    return true if has_cave_encounters? && !(terrain_tag.id == :Sand)   # i.e. this map is a cave
    return true if has_land_encounters? && terrain_tag.land_wild_encounters
    return false
  end

  # Returns whether a wild encounter should happen, based on its encounter
  # chance. Called when taking a step and by Rock Smash.
  def encounter_triggered?(enc_type, repel_active = false, triggered_by_step = true)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    return false if $game_system.encounter_disabled
    return false if !$Trainer
    return false if $DEBUG && Input.press?(Input::CTRL)
    # Check if enc_type has a defined step chance/encounter table
    return false if !@step_chances[enc_type] || @step_chances[enc_type] == 0
    return false if !has_encounter_type?(enc_type)
    # Get base encounter chance and minimum steps grace period
    encounter_chance = @step_chances[enc_type].to_f
    min_steps_needed = (8 - encounter_chance / 10).clamp(0, 8).to_f
    # Apply modifiers to the encounter chance and the minimum steps amount
    if triggered_by_step
      encounter_chance += @chance_accumulator / 200
      encounter_chance *= 0.8 if $PokemonGlobal.bicycle
    end
    first_pkmn = $Trainer.first_pokemon
    if first_pkmn
      case first_pkmn.item_id
      when :CLEANSETAG
        encounter_chance *= 2.0 / 3
        min_steps_needed *= 4 / 3.0
      when :PUREINCENSE
        encounter_chance *= 2.0 / 3
        min_steps_needed *= 4 / 3.0
	  end
    end 
    # Wild encounters are much less likely to happen for the first few steps
    # after a previous wild encounter
    if triggered_by_step && @step_count < min_steps_needed
      @step_count += 1
      return false if rand(100) >= encounter_chance * 5 / (@step_chances[enc_type] + @chance_accumulator / 200)
    end
    # Decide whether the wild encounter should actually happen
    return true if rand(100) < encounter_chance
    # If encounter didn't happen, make the next step more likely to produce one
    if triggered_by_step
      @chance_accumulator += @step_chances[enc_type]
      @chance_accumulator = 0 if repel_active
    end
    return false
  end

  # Returns whether an encounter with the given Pokémon should be allowed after
  # taking into account Repels and ability effects.
  def allow_encounter?(enc_data, repel_active = false)
    return false if !enc_data
    # Repel
    if repel_active && !pbPokeRadarOnShakingGrass
		@chance_accumulator = 0
		return false
    end
    return true
  end
  
  # Returns the encounter method that the current encounter should be generated
  # from, depending on the player's current location.
  def encounter_type
    time = pbGetTimeNow
    ret = nil
    if $PokemonGlobal.surfing
	  echo("#{$game_map.terrain_tag($game_player.x, $game_player.y).id}\n")
	  # Active water encounters
	  if $game_map.terrain_tag($game_player.x, $game_player.y).id == :ActiveWater
		ret = find_valid_encounter_type_for_time(:ActiveWater, time)
	  end
	  
      ret = find_valid_encounter_type_for_time(:Water, time) if !ret
    else   # Land/Cave (can have both in the same map)
	  # Mud encounters
	  if $game_map.terrain_tag($game_player.x, $game_player.y).id == :Mud
		ret = find_valid_encounter_type_for_time(:Mud, time)
	  end
	  # Tall grass encounters
	  if $game_map.terrain_tag($game_player.x, $game_player.y).deep_bush
		ret = find_valid_encounter_type_for_time(:LandTall, time)
	  end
	  # Land encounters
      if !ret && has_land_encounters? && $game_map.terrain_tag($game_player.x, $game_player.y).land_wild_encounters
        ret = :BugContest if pbInBugContest? && has_encounter_type?(:BugContest)
        ret = find_valid_encounter_type_for_time(:Land, time) if !ret
      end
	  # Cave encounters
      if !ret && has_cave_encounters?
        ret = find_valid_encounter_type_for_time(:Cave, time)
      end
    end
    return ret
  end


  # For the current map, randomly chooses a species and level from the encounter
  # list for the given encounter type. Returns nil if there are none defined.
  # A higher chance_rolls makes this method prefer rarer encounter slots.
  def choose_wild_pokemon(enc_type, chance_rolls = 1)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    enc_list = @encounter_tables[enc_type]
    return nil if !enc_list || enc_list.length == 0
	
	# 25% chance to only roll on Pokemon not yet caught
	uncaught_enc_list = enc_list.clone.delete_if{|e| $Trainer.owned?(e[1])}
	echo("#{uncaught_enc_list}\n")
	if uncaught_enc_list.length > 0 && rand(100) < 25
		echo("Only rolling encounters for uncaught Pokemon!\n")
		enc_list = uncaught_enc_list
	end
	
    enc_list.sort! { |a, b| b[0] <=> a[0] }   # Highest probability first
    # Calculate the total probability value
    chance_total = 0
    enc_list.each { |a| chance_total += a[0] }
    # Choose a random entry in the encounter table based on entry probabilities
    rnd = 0
    chance_rolls.times do
      r = rand(chance_total)
      rnd = r if r > rnd   # Prefer rarer entries if rolling repeatedly
    end
    encounter = nil
    enc_list.each do |enc|
      rnd -= enc[0]
      next if rnd >= 0
      encounter = enc
      break
    end
    # Get the chosen species and level
    level = rand(encounter[2]..encounter[3])
    # Return [species, level]
    return [encounter[1], level]
  end

  # For the given map, randomly chooses a species and level from the encounter
  # list for the given encounter type. Returns nil if there are none defined.
  # Used by the Bug Catching Contest to choose what the other participants
  # caught.
  def choose_wild_pokemon_for_map(map_ID, enc_type)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    # Get the encounter table
    encounter_data = GameData::Encounter.get(map_ID, $PokemonGlobal.encounter_version)
    return nil if !encounter_data
    enc_list = encounter_data.types[enc_type]
    return nil if !enc_list || enc_list.length == 0
	
	# 25% chance to only roll on Pokemon not yet caught
	uncaught_enc_list = enc_list.delete_if{|e| $Trainer.owned?(e[1])}
	echo("#{uncaught_enc_list}\n")
	if uncaught_enc_list.length > 0 && rand(100) < 25
		echo("Only rolling encounters for uncaught Pokemon!\n")
		enc_list = uncaught_enc_list
	end
	
    # Calculate the total probability value
    chance_total = 0
    enc_list.each { |a| chance_total += a[0] }
    # Choose a random entry in the encounter table based on entry probabilities
    rnd = 0
    chance_rolls.times do
      r = rand(chance_total)
      rnd = r if r > rnd   # Prefer rarer entries if rolling repeatedly
    end
    encounter = nil
    enc_list.each do |enc|
      rnd -= enc[0]
      next if rnd >= 0
      encounter = enc
      break
    end
    # Return [species, level]
    level = rand(encounter[2]..encounter[3])
    return [encounter[1], level]
  end
end

# Tall Grass

GameData::EncounterType.register({
  :id             => :LandTall,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Mud

GameData::TerrainTag.register({
  :id                     => :Mud,
  :id_number              => 17,
  :battle_environment     => :Rock,
  :land_wild_encounters	  => true,
  :must_walk              => true,
  :slows				  => true
})

GameData::EncounterType.register({
  :id             => :Mud,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Active Water

GameData::TerrainTag.register({
  :id                     => :ActiveWater,
  :id_number              => 18,
  :battle_environment     => :Water,
  :can_surf               => true
})

GameData::EncounterType.register({
  :id             => :ActiveWater,
  :type           => :water,
  :trigger_chance => 15,
  :old_slots      => [60, 30, 5, 4, 1]
})