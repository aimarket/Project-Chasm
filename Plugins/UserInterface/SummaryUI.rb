class PokemonSummary_Scene
	def pbStartScene(party,partyindex,inbattle=false)
		@viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
		@viewport.z = 99999
		@party      = party
		@partyindex = partyindex
		@pokemon    = @party[@partyindex]
		@inbattle   = inbattle
		@page = 1
		@forget = false
		@typebitmap    = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
		@markingbitmap = AnimatedBitmap.new("Graphics/Pictures/Summary/markings")
		@sprites = {}
		@sprites["background"] = IconSprite.new(0,0,@viewport)
		@sprites["pokemon"] = PokemonSprite.new(@viewport)
		@sprites["pokemon"].setOffset(PictureOrigin::Center)
		@sprites["pokemon"].x = 104
		@sprites["pokemon"].y = 206
		@sprites["pokemon"].setPokemonBitmap(@pokemon)
		@sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
		@sprites["pokeicon"].setOffset(PictureOrigin::Center)
		@sprites["pokeicon"].x       = 46
		@sprites["pokeicon"].y       = 92
		@sprites["pokeicon"].visible = false
		@sprites["itemicon"] = ItemIconSprite.new(30,320,@pokemon.item_id,@viewport)
		@sprites["itemicon"].blankzero = true
		@sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
		pbSetSystemFont(@sprites["overlay"].bitmap)
		@sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
		@sprites["movepresel"].visible     = false
		@sprites["movepresel"].preselected = true
		@sprites["movesel"] = MoveSelectionSprite.new(@viewport)
		@sprites["movesel"].visible = false
		@sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
		@sprites["ribbonpresel"].visible     = false
		@sprites["ribbonpresel"].preselected = true
		@sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
		@sprites["ribbonsel"].visible = false
		@sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
		@sprites["uparrow"].x = 350
		@sprites["uparrow"].y = 56
		@sprites["uparrow"].play
		@sprites["uparrow"].visible = false
		@sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
		@sprites["downarrow"].x = 350
		@sprites["downarrow"].y = 260
		@sprites["downarrow"].play
		@sprites["downarrow"].visible = false
		@sprites["markingbg"] = IconSprite.new(260,88,@viewport)
		@sprites["markingbg"].setBitmap("Graphics/Pictures/Summary/overlay_marking")
		@sprites["markingbg"].visible = false
		@sprites["markingoverlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
		@sprites["markingoverlay"].visible = false
		pbSetSystemFont(@sprites["markingoverlay"].bitmap)
		@sprites["markingsel"] = IconSprite.new(0,0,@viewport)
		@sprites["markingsel"].setBitmap("Graphics/Pictures/Summary/cursor_marking")
		@sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height/2
		@sprites["markingsel"].visible = false
		@sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
		@sprites["messagebox"].viewport       = @viewport
		@sprites["messagebox"].visible        = false
		@sprites["messagebox"].letterbyletter = true
		pbBottomLeftLines(@sprites["messagebox"],2)
		drawPage(@page)
		pbFadeInAndShow(@sprites) { pbUpdate }
	end


	def pbStartForgetScene(party,partyindex,move_to_learn)
		@viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
		@viewport.z = 99999
		@party      = party
		@partyindex = partyindex
		@pokemon    = @party[@partyindex]
		@page = 4
		@forget = true
		@typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
		@extraReminderBitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Rework/extra_info_reminder"))
		@sprites = {}
		@sprites["background"] = IconSprite.new(0,0,@viewport)
		@sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
		pbSetSystemFont(@sprites["overlay"].bitmap)
		@sprites["pokemon"] = PokemonSprite.new(@viewport)
		@sprites["pokemon"].setOffset(PictureOrigin::Center)
		@sprites["pokemon"].x = 104
		@sprites["pokemon"].y = 206
		@sprites["pokemon"].setPokemonBitmap(@pokemon)
		@sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
		@sprites["pokeicon"].setOffset(PictureOrigin::Center)
		@sprites["pokeicon"].x       = 46
		@sprites["pokeicon"].y       = 92
		@sprites["pokeicon"].visible = false
		@sprites["itemicon"] = ItemIconSprite.new(30,320,@pokemon.item_id,@viewport)
		@sprites["itemicon"].blankzero = true
		@sprites["movesel"] = MoveSelectionSprite.new(@viewport,!move_to_learn.nil?)
		@sprites["movesel"].visible = false
		@sprites["movesel"].visible = true
		@sprites["movesel"].index   = 0
		@sprites["extraReminder"] = SpriteWrapper.new(@viewport)
		@sprites["extraReminder"].bitmap = @extraReminderBitmap.bitmap
		@sprites["extraReminder"].x = 34
		@sprites["extraReminder"].y = 64
		new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
		drawSelectedMove(new_move,@pokemon.moves[0])
		pbFadeInAndShow(@sprites)
	end
	
	def drawPage(page)
		if @pokemon.egg?
		  drawPageOneEgg
		  return
		end
		@sprites["itemicon"].item = @pokemon.item_id
		overlay = @sprites["overlay"].bitmap
		overlay.clear
		base   = Color.new(248,248,248)
		shadow = Color.new(104,104,104)
		# Set background image
		@sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_#{page}")
		imagepos=[]
		# Show the Poké Ball containing the Pokémon
		ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball)
		if !pbResolveBitmap(ballimage)
		  ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%02d", pbGetBallType(@pokemon.poke_ball))
		end
		imagepos.push([ballimage,14,60])
		# Show status/fainted/Pokérus infected icon
		status = 0
		if @pokemon.fainted?
		  status = GameData::Status::DATA.keys.length / 2
		elsif @pokemon.status != :NONE
		  status = GameData::Status.get(@pokemon.status).id_number
		  status = 8 if @pokemon.status==:POISON && @pokemon.statusCount>0
		elsif @pokemon.pokerusStage == 1
		  status = GameData::Status::DATA.keys.length / 2 + 1
		end
		status -= 1
		if status >= 0
		  imagepos.push(["Graphics/Pictures/Rework/statuses",124,100,0,16*status,44,16])
		end
		# Show Pokérus cured icon
		if @pokemon.pokerusStage==2
		  imagepos.push([sprintf("Graphics/Pictures/Summary/icon_pokerus"),176,100])
		end
		# Show shininess star
		if @pokemon.shiny?
		  imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134])
		end
		# Draw all images
		pbDrawImagePositions(overlay,imagepos)
		# Write various bits of text
		pagename = [_INTL("INFO"),
					_INTL("TRAINER MEMO"),
					_INTL("SKILLS"),
					_INTL("MOVES"),
					_INTL("RIBBONS")][page-1]
		textpos = [
		   [pagename,26,10,0,base,shadow],
		   [@pokemon.name,46,56,0,base,shadow],
		   [@pokemon.level.to_s,46,86,0,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Item"),66,312,0,base,shadow]
		]
		# Write the held item's name
		if @pokemon.hasItem?
		  textpos.push([@pokemon.item.name,16,346,0,Color.new(64,64,64),Color.new(176,176,176)])
		else
		  textpos.push([_INTL("None"),16,346,0,Color.new(192,200,208),Color.new(208,216,224)])
		end
		# Write the gender symbol
		if @pokemon.male?
		  textpos.push([_INTL("♂"),178,56,0,Color.new(24,112,216),Color.new(136,168,208)])
		elsif @pokemon.female?
		  textpos.push([_INTL("♀"),178,56,0,Color.new(248,56,32),Color.new(224,152,144)])
		end
		# Draw all text
		pbDrawTextPositions(overlay,textpos)
		# Draw the Pokémon's markings
		drawMarkings(overlay,84,292)
		# Draw page-specific information
		case page
		when 1 then drawPageOne
		when 2 then drawPageTwo
		when 3 then drawPageThree
		when 4 then drawPageFour
		when 5 then drawPageFive
		end
	end
	
	def drawPageFour
		overlay = @sprites["overlay"].bitmap
		moveBase   = Color.new(64,64,64)
		moveShadow = Color.new(176,176,176)
		ppBase   = [moveBase,                # More than 1/2 of total PP
					Color.new(248,192,0),    # 1/2 of total PP or less
					Color.new(248,136,32),   # 1/4 of total PP or less
					Color.new(248,72,72)]    # Zero PP
		ppShadow = [moveShadow,             # More than 1/2 of total PP
					Color.new(144,104,0),   # 1/2 of total PP or less
					Color.new(144,72,24),   # 1/4 of total PP or less
					Color.new(136,48,48)]   # Zero PP
		@sprites["pokemon"].visible = true
		@sprites["pokeicon"].visible = false
		@sprites["itemicon"].visible = true
		textpos  = []
		imagepos = []
		# Write move names, types and PP amounts for each known move
		yPos = 92
		for i in 0...Pokemon::MAX_MOVES
		  move=@pokemon.moves[i]
		  if move
			type_number = GameData::Type.get(move.type).id_number
			imagepos.push(["Graphics/Pictures/types", 248, yPos + 8, 0, type_number * 28, 64, 28])
			textpos.push([move.name,316,yPos,0,moveBase,moveShadow])
			if move.total_pp>0
			  textpos.push([_INTL("PP"),342,yPos+32,0,moveBase,moveShadow])
			  ppfraction = 0
			  if move.pp==0;                  ppfraction = 3
			  elsif move.pp*4<=move.total_pp; ppfraction = 2
			  elsif move.pp*2<=move.total_pp; ppfraction = 1
			  end
			  textpos.push([sprintf("%d/%d",move.pp,move.total_pp),460,yPos+32,1,ppBase[ppfraction],ppShadow[ppfraction]])
			end
		  else
			textpos.push(["-",316,yPos,0,moveBase,moveShadow])
			textpos.push(["--",442,yPos+32,1,moveBase,moveShadow])
		  end
		  yPos += 64
		end
		# Draw all text and images
		pbDrawTextPositions(overlay,textpos)
		pbDrawImagePositions(overlay,imagepos)
	end
	
  def drawPageFourSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(104,104,104)
    moveBase   = Color.new(64,64,64)
    moveShadow = Color.new(176,176,176)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248,192,0),    # 1/2 of total PP or less
                Color.new(248,136,32),   # 1/4 of total PP or less
                Color.new(248,72,72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144,104,0),   # 1/2 of total PP or less
                Color.new(144,72,24),   # 1/4 of total PP or less
                Color.new(136,48,48)]   # Zero PP
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_movedetail")
    end
    # Write various bits of text
    textpos = [
       [_INTL("MOVES"),26,10,0,base,shadow],
       [_INTL("CATEGORY"),20,116,0,base,shadow],
       [_INTL("POWER"),20,148,0,base,shadow],
       [_INTL("ACCURACY"),20,180,0,base,shadow]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 92
    yPos -= 76 if move_to_learn
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    for i in 0...limit
      move = @pokemon.moves[i]
      if i==Pokemon::MAX_MOVES
        move = move_to_learn
        yPos += 20
      end
      if move
        type_number = GameData::Type.get(move.type).id_number
        imagepos.push(["Graphics/Pictures/types", 248, yPos + 8, 0, type_number * 28, 64, 28])
        textpos.push([move.name,316,yPos,0,moveBase,moveShadow])
        if move.total_pp>0
          textpos.push([_INTL("PP"),342,yPos+32,0,moveBase,moveShadow])
          ppfraction = 0
          if move.pp==0;                  ppfraction = 3
          elsif move.pp*4<=move.total_pp; ppfraction = 2
          elsif move.pp*2<=move.total_pp; ppfraction = 1
          end
          textpos.push([sprintf("%d/%d",move.pp,move.total_pp),460,yPos+32,1,ppBase[ppfraction],ppShadow[ppfraction]])
        end
      else
        textpos.push(["-",316,yPos,0,moveBase,moveShadow])
        textpos.push(["--",442,yPos+32,1,moveBase,moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
	if !@forget
		# Draw Pokémon's type icon(s)
		type1_number = GameData::Type.get(@pokemon.type1).id_number
		type2_number = GameData::Type.get(@pokemon.type2).id_number
		type1rect = Rect.new(0, type1_number * 28, 64, 28)
		type2rect = Rect.new(0, type2_number * 28, 64, 28)
		if @pokemon.type1==@pokemon.type2
		  overlay.blt(130,78,@typebitmap.bitmap,type1rect)
		else
		  overlay.blt(96,78,@typebitmap.bitmap,type1rect)
		  overlay.blt(166,78,@typebitmap.bitmap,type2rect)
		end
	end
  end

  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFourSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base = Color.new(64, 64, 64)
    shadow = Color.new(176, 176, 176)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
	@sprites["pokeicon"].visible = false if @forget
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.base_damage
    when 0 then textpos.push(["---", 216, 148, 1, base, shadow])   # Status move
    when 1 then textpos.push(["???", 216, 148, 1, base, shadow])   # Variable power move
    else        textpos.push([selected_move.base_damage.to_s, 216, 148, 1, base, shadow])
    end
    if selected_move.accuracy == 0
      textpos.push(["---", 216, 180, 1, base, shadow])
    else
      textpos.push(["#{selected_move.accuracy}%", 216 + overlay.text_size("%").width, 180, 1, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/Pictures/category", 166, 124, 0, selected_move.category * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 4, 222, 230, 5, selected_move.description, base, shadow)
  end
	  
	def pbEndScene
		pbFadeOutAndHide(@sprites) { pbUpdate }
		pbDisposeSpriteHash(@sprites)
		@typebitmap.dispose
		@extraReminderBitmap.dispose if @extraReminderBitmap
		@markingbitmap.dispose if @markingbitmap
		@viewport.dispose
	end

	def pbChooseMoveToForget(move_to_learn)
		new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
		selmove = 0
		maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
		@sprites["pokemon"].visible = true if !@forget
		@sprites["itemicon"].visible = false
		loop do
		  Graphics.update
		  Input.update
		  pbUpdate
		  if Input.trigger?(Input::BACK)
			selmove = Pokemon::MAX_MOVES
			pbPlayCloseMenuSE if new_move
			break
		  elsif Input.trigger?(Input::USE)
			pbPlayDecisionSE
			break
		  elsif Input.trigger?(Input::UP)
			selmove -= 1
			selmove = maxmove if selmove<0
			if selmove<Pokemon::MAX_MOVES && selmove>=@pokemon.numMoves
			  selmove = @pokemon.numMoves-1
			end
			@sprites["movesel"].index = selmove
			selected_move = (selmove==Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
			drawSelectedMove(new_move,selected_move)
		  elsif Input.trigger?(Input::DOWN)
			selmove += 1
			selmove = 0 if selmove>maxmove
			if selmove<Pokemon::MAX_MOVES && selmove>=@pokemon.numMoves
			  selmove = (new_move) ? maxmove : 0
			end
			@sprites["movesel"].index = selmove
			selected_move = (selmove==Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
			drawSelectedMove(new_move,selected_move)
		  elsif Input.trigger?(Input::ACTION)
			pbFadeOutIn {
				pbTemporaryStatsScreen()
				@sprites["movesel"].visible = false
				@sprites["itemicon"].visible = false
				@sprites["extraReminder"].visible = false
				@sprites["pokemon"].visible = true
			}
			loop do
				Graphics.update
				Input.update
				if Input.trigger?(Input::BACK)
					pbPlayCancelSE()
					break
				end
			end
			@sprites["movesel"].visible = true
			@sprites["itemicon"].visible = true
			@sprites["extraReminder"].visible = true
			@sprites["pokemon"].visible = false
			drawSelectedMove(new_move,@pokemon.moves[0])
			pbFadeInAndShow(@sprites)
		  end
		end
		return (selmove==Pokemon::MAX_MOVES) ? -1 : selmove
	end

	def pbTemporaryStatsScreen()
		@sprites["itemicon"].item = @pokemon.item_id
		overlay = @sprites["overlay"].bitmap
		overlay.clear
		base   = Color.new(248,248,248)
		shadow = Color.new(104,104,104)
		# Set background image
		@sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_3z")
		imagepos = []
		# Show the Poké Ball containing the Pokémon
		ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball)
		if !pbResolveBitmap(ballimage)
			ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%02d", pbGetBallType(@pokemon.poke_ball))
		end
		imagepos.push([ballimage,14,60])
		# Draw all images
		pbDrawImagePositions(overlay,imagepos)
		# Write various bits of text
		pagename = _INTL("SKILLS")
		textpos = [
		   [pagename,26,10,0,base,shadow],
		   [@pokemon.name,46,56,0,base,shadow],
		   [@pokemon.level.to_s,46,86,0,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Item"),66,312,0,base,shadow]
		]
		# Write the held item's name
		if @pokemon.hasItem?
		  textpos.push([@pokemon.item.name,16,346,0,Color.new(64,64,64),Color.new(176,176,176)])
		else
		  textpos.push([_INTL("None"),16,346,0,Color.new(192,200,208),Color.new(208,216,224)])
		end
		# Write the gender symbol
		if @pokemon.male?
		  textpos.push([_INTL("♂"),178,56,0,Color.new(24,112,216),Color.new(136,168,208)])
		elsif @pokemon.female?
		  textpos.push([_INTL("♀"),178,56,0,Color.new(248,56,32),Color.new(224,152,144)])
		end
		# Draw all text
		pbDrawTextPositions(overlay,textpos)	
		# Draw page-specific information
		base   = Color.new(248,248,248)
		shadow = Color.new(104,104,104)
		# Write various bits of text
		textpos = [
		   [_INTL("HP"),292,70,2,base,shadow],
		   [sprintf("%d/%d",@pokemon.hp,@pokemon.totalhp),462,70,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Attack"),248,114,0,base,shadow],
		   [sprintf("%d",@pokemon.attack),456,114,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Defense"),248,146,0,base,shadow],
		   [sprintf("%d",@pokemon.defense),456,146,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Sp. Atk"),248,178,0,base,shadow],
		   [sprintf("%d",@pokemon.spatk),456,178,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Sp. Def"),248,210,0,base,shadow],
		   [sprintf("%d",@pokemon.spdef),456,210,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Speed"),248,242,0,base,shadow],
		   [sprintf("%d",@pokemon.speed),456,242,1,Color.new(64,64,64),Color.new(176,176,176)],
		   [_INTL("Ability"),224,278,0,base,shadow]
		]
		# Draw ability name and description
		ability = @pokemon.ability
		if ability
		  textpos.push([ability.name,362,278,0,Color.new(64,64,64),Color.new(176,176,176)])
		  drawTextEx(overlay,224,320,282,2,ability.description,Color.new(64,64,64),Color.new(176,176,176))
		end
		# Draw Pokémon's type icon(s)
		type1_number = GameData::Type.get(@pokemon.type1).id_number
		type2_number = GameData::Type.get(@pokemon.type2).id_number
		type1rect = Rect.new(0, type1_number * 28, 64, 28)
		type2rect = Rect.new(0, type2_number * 28, 64, 28)
		if @pokemon.type1==@pokemon.type2
		  overlay.blt(310,18,@typebitmap.bitmap,type1rect)
		else
		  overlay.blt(276,18,@typebitmap.bitmap,type1rect)
		  overlay.blt(346,18,@typebitmap.bitmap,type2rect)
		end
		# Draw all text
		pbDrawTextPositions(overlay,textpos)
	end
end