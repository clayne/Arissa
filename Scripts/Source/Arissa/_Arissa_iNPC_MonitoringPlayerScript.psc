Scriptname _Arissa_iNPC_MonitoringPlayerScript extends Quest 
{Monitors the player's actions and quest states. Runs only when Arissa is following.}

import utility
import math

_Arissa_iNPC_Behavior Property iNPCSystem auto
ReferenceAlias Property iNPC auto
Actor property PlayerRef auto
Actor property CamillaValeriusRef auto
GlobalVariable property _Arissa_DebugVar auto
GlobalVariable property GameHour auto
GlobalVariable property _Arissa_Regard auto
ActorBase property iNPC_Horse auto
ObjectReference property MyHorse auto hidden
Package property _ArissaFollowFar_RideHorse auto
keyword property LocTypeDungeon auto
Message property _ArissaTownRoamMessage auto
Message property _ArissaTownRoamEndMessage auto
Quest property _Arissa_MQ01 auto
Quest property _Arissa_MQ02 auto
GlobalVariable property _Arissa_CurrentTownRoamArea auto
GlobalVariable property _Arissa_ReactionIndex auto
Quest property _Arissa_Commentary_Reactions auto
Outfit property _Arissa_Armor1_Outfit auto
Outfit property _Arissa_Armor2_Outfit auto
Outfit property _Arissa_Armor3_Outfit auto
Outfit property _Arissa_BaseOutfit auto
Armor property _Arissa_ArmorThievesGuildVariantGauntlets auto
Armor property _Arissa_ArmorThievesGuildVariantBoots auto
Armor property _Arissa_ArmorThievesGuildVariantCuirass auto
Keyword property LocTypeHouse auto
Keyword property LocTypePlayerHouse auto
Keyword property LocTypeInn auto
Keyword property LocTypeStore auto
Keyword property LocTypeTown auto
Keyword property LocTypeCastle auto
Keyword property LocTypeCity auto
Activator property dunFrostmereCryptPaleBladeAct auto
Formlist property PuzzleDoorKeyholes auto
Quest property _Arissa_TheftQuestOngoingScene auto
Quest property _Arissa_AmbientDialogue auto
Quest property _Arissa_Scenes_CamillaQuest auto
MiscObject property Gold001 auto
MagicEffect property DA11AbFortifyHealth auto
Spell property _Arissa_SummonSpell auto
Spell property _Arissa_RegardSpell auto
Location property RiverwoodLucansDryGoodsLocation auto
Location property _Arissa_SkygroveDeepfallLocation auto
ObjectReference property MQ02DoorRef auto
_Arissa_Compatibility property Compatibility auto
ReferenceAlias property Alias_Compatibility auto
Keyword property ActorTypeNPC auto
Idle property pa_1HMKillMoveBackStab auto
Idle property KillMoveSneakH2HSleeper auto
Spell property Invisibility auto
Keyword property MagicInvisibility auto
ObjectReference property _Arissa_MQ02CaveDoor auto
ObjectReference property _Arissa_MQ02CaveBarrier auto
Light property Torch01 auto

int blink_attack_ready_counter = 0
int removed_torch_count = 0

int Property UpdateInterval auto				;Default: 1
float Property SettleRadius auto				;Default: 150.0

int iInTownRoamArea = -1

int __historySize = 8 ; remember to update the declarations if necessary
float[] __playerPosX
float[] __playerPosY
float[] __playerPosZ

int MQ02QuestCounter = 7
bool MQ02Triggered = false

float OffsetX = 150.000
float Angle = 90.0000
float OffsetZ = 0.000000
float OffsetY = 150.000

GlobalVariable property _Arissa_Update1_2 auto
GlobalVariable property _Arissa_Update1_3 auto
GlobalVariable property _Arissa_Update2_1 auto
GlobalVariable property _Arissa_Update2_2 auto

Function Setup()
	; history of player position over the last __historySize updates
	__playerPosX = new float[8]
	__playerPosY = new float[8]
	__playerPosZ = new float[8]

	; initialize the position histories with faraway junk datums
	;  so that we won't immediately assume the player is holding 
	;  still when the quest starts
	Actor _player = PlayerRef
	int count = 0
	while (count < __historySize)
		__playerPosX[count] = _player.X + 1000
		__playerPosY[count] = _player.Y + 1000
		__playerPosZ[count] = _player.Z + 1000
		count += 1
	endwhile

	RegisterForSingleUpdateGameTime(12)
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Event OnUpdate()
	UpgradeTasks()
	UpdateWaitState()
	UpdateFollowDistance()
	CheckCombat()	
	
	if CheckSocialCondition()
		TryToSandboxAroundPlayer()
	endif
	TryToGiveTheftResults()
	TryToSaySomethingAboutSurroundings()

	TryToRideHorse()
	TryToDoThingsWhenPlayerNotLooking()

	TryToStartQuestsImmediate()

	if iNPCSystem.iNPC.GetActorRef().HasLOS(PlayerRef)
		UpdateStats()
	else
		iNPCSystem.UpdateAllStats()
	endif

	CheckRegard()

	RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnUpdateGameTime()
	UpdateLongTermMood()
	RegressMood()
	ResetTempDialogueFlags()
	TryToStartQuestsLongTerm()

	RegisterForSingleUpdateGameTime(12)
endEvent

function CheckCombat()
	if blink_attack_ready_counter > 0
		blink_attack_ready_counter -= 1
		;debug.trace("[Arissa] blink attack ready in " + blink_attack_ready_counter)
		return
	endif
		
	Actor arissa = iNPCSystem.iNPC.GetActorRef()
	if arissa.IsInCombat()
		Actor ctarg = arissa.GetCombatTarget()
		if ctarg
			if arissa.GetActorValuePercentage("Health") > 0.2 && ctarg.GetActorValuePercentage("Health") <= 0.25 && \
				PlayerRef.GetActorValuePercentage("Health") <= 0.80 && ctarg.GetRace().HasKeyword(ActorTypeNPC) && \
				arissa.GetEquippedItemType(1) <= 2 && RandomFloat() <= 0.30
				;debug.trace("[Arissa] Performing blink attack!")
				DoBlinkAttack(arissa, ctarg)
			endif
		endif
	endif
endFunction

function DoBlinkAttack(Actor akActor, Actor akTarget)
	;_Arissa_BlinkAttackGFXSpell.Cast(akActor, akActor)
	Invisibility.Cast(akActor, akActor)
	int i = 0
	while !akActor.HasMagicEffectWithKeyword(MagicInvisibility) && i < 50
		wait(0.1)
		i += 1
	endWhile
	wait(3)
	akActor.MoveTo(akTarget, -120 * Math.Sin(akTarget.GetAngleZ()), -120 * Math.Cos(akTarget.GetAngleZ()), 0, abMatchRotation = true)
	if (akActor.GetEquippedItemType(1) == 1 || akActor.GetEquippedItemType(1) == 2)
		akActor.PlayIdleWithTarget(pa_1HMKillMoveBackStab, akTarget)
	elseif akActor.GetEquippedItemType(1) == 0
		akActor.PlayIdleWithTarget(KillMoveSneakH2HSleeper, akTarget)
	endif
	wait(2)
	akActor.DispelSpell(Invisibility)
	blink_attack_ready_counter = 30
endFunction

function UpgradeTasks()
	Actor ArissaRef = iNPCSystem.iNPC.GetActorRef()

	if _Arissa_Update1_2.GetValueInt() != 2
		debug.trace("[Arissa Debug] Upgrade 1.2 Tasks")
		;Set long-term outfit
		;iNPCSystem.iNPC.GetActorRef().SetOutfit(_Arissa_Armor1_Outfit)

		;Fix issue with Arissa not making it out of MQ03 Cave
		if ArissaRef.GetCurrentLocation() == _Arissa_SkygroveDeepfallLocation && PlayerRef.GetCurrentLocation() != _Arissa_SkygroveDeepfallLocation
			ArissaRef.MoveTo(Game.GetPlayer())
			_Arissa_MQ02.CompleteAllObjectives()
			_Arissa_MQ02.CompleteQuest()
			_Arissa_MQ02.SetStage(100)
			if iNPCSystem.CanWait == false
				iNPCSystem.CanWait = true
			endif
			MQ02DoorRef.Disable()
		endif

		_Arissa_Update1_2.SetValueInt(2)
	endif

	if _Arissa_Update1_3.GetValueInt() != 2
		debug.trace("[Arissa Debug] Upgrade 1.3 Tasks")
		Alias_Compatibility.ForceRefIfEmpty(Game.GetPlayer())
		Compatibility.CompatibilityCheck()
		_Arissa_Update1_3.SetValueInt(2)
	endif

	if _Arissa_Update2_1.GetValueInt() != 2
		debug.trace("[Arissa Debug] Upgrade 2.1 Tasks")
		; Set the base outfit
		ArissaRef.SetOutfit(_Arissa_BaseOutfit)

		; Make sure Arissa can equip other gear
		if _Arissa_MQ01.IsCompleted()
			if ArissaRef.GetItemCount(_Arissa_ArmorThievesGuildVariantBoots) == 0
				ArissaRef.AddItem(_Arissa_ArmorThievesGuildVariantBoots)
			endif
			if ArissaRef.GetItemCount(_Arissa_ArmorThievesGuildVariantGauntlets) == 0
				ArissaRef.AddItem(_Arissa_ArmorThievesGuildVariantGauntlets)
			endif
			if ArissaRef.GetItemCount(_Arissa_ArmorThievesGuildVariantCuirass) == 0
				ArissaRef.AddItem(_Arissa_ArmorThievesGuildVariantCuirass)
			endif
			ArissaRef.EquipItem(_Arissa_ArmorThievesGuildVariantGauntlets)
			ArissaRef.EquipItem(_Arissa_ArmorThievesGuildVariantBoots)
			ArissaRef.EquipItem(_Arissa_ArmorThievesGuildVariantCuirass)
		endif

		; Set the state of the MQ02 Cave
		if _Arissa_MQ02.IsRunning() || _Arissa_MQ02.IsCompleted()
			_Arissa_MQ02CaveDoor.Enable()
			_Arissa_MQ02CaveBarrier.Disable()
		endif
		_Arissa_Update2_1.SetValueInt(2)
	endif

	if _Arissa_Update2_2.GetValueInt() != 2
		if _Arissa_MQ01.IsCompleted()
			debug.trace("[Arissa Debug] Upgrade 2.2 Task: Stopping MQ01 after completion")
			_Arissa_MQ01.Stop()
		endif
		_Arissa_Update2_2.SetValueInt(2)
	endif

endFunction

function TryToStartQuestsLongTerm()
	;Pop MQ02
	if MQ02QuestCounter <= 0 && !MQ02Triggered && !_Arissa_MQ02.IsCompleted() && !_Arissa_MQ02.IsRunning()
		_Arissa_MQ02.Start()
		MQ02Triggered = true
	else
		MQ02QuestCounter -= 1
	endif

	if iNPCSystem.MQ102TalkCounter > 0
		iNPCSystem.MQ102TalkCounter -= 1
	endif
endFunction

function TryToStartQuestsImmediate()
	;Pop Camilla Scene
	;if iNPCSystem.ArissaMetCamilla == false
	;	if iNPCSystem.iNPC.GetActorRef().IsInLocation(RiverwoodLucansDryGoodsLocation) && CamillaValeriusRef.IsInLocation(RiverwoodLucansDryGoodsLocation) && !CamillaValeriusRef.IsDead()
	;		_Arissa_Scenes_CamillaQuest.Start()
	;		iNPCSystem.ArissaMetCamilla = true
	;	endif
	;endif
endFunction

function UpdateStats()
	;INCREASES
	;Brawls
	int a = Game.QueryStat("Brawls Won")
	if a > iNPCSystem.PlayerStat_BrawlsWon
		iNPCSystem.PlayerStat_BrawlsWon = a
		iNPCSystem.IncreaseRegardModerate()
		_Arissa_ReactionIndex.SetValueInt(2)
		_Arissa_Commentary_Reactions.Start()
	endif

	;Backstabs
	int b = Game.QueryStat("Backstabs")
	if b > iNPCSystem.PlayerStat_Backstabs 
		iNPCSystem.PlayerStat_Backstabs = b
		iNPCSystem.IncreaseRegardMinor()
	endif

	;Locations Discovered
	int c = Game.QueryStat("Locations Discovered")
	if c > iNPCSystem.PlayerStat_LocationsDiscovered
		iNPCSystem.PlayerStat_LocationsDiscovered = c
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Dungeons Cleared
	int d = Game.QueryStat("Dungeons Cleared")
	if d > iNPCSystem.PlayerStat_DungeonsCleared
		iNPCSystem.PlayerStat_DungeonsCleared = d
		iNPCSystem.IncreaseRegardMinor()
	endif

	;Days Passed
	int e = Game.QueryStat("Days Passed")
	if e > iNPCSystem.PlayerStat_DaysPassed
		iNPCSystem.PlayerStat_DaysPassed = e
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Persuasions
	int f = Game.QueryStat("Persuasions")
	if f > iNPCSystem.PlayerStat_Persuasions
		iNPCSystem.PlayerStat_Persuasions = f
		iNPCSystem.IncreaseRegardModerate()
	endif

	;Bribes
	int g = Game.QueryStat("Bribes")
	if g > iNPCSystem.PlayerStat_Bribes
		iNPCSystem.PlayerStat_Bribes = g
		iNPCSystem.IncreaseRegardModerate()
	endif

	;Quests Completed
	int h = Game.QueryStat("Quests Completed")
	if h > iNPCSystem.PlayerStat_QuestsCompleted
		iNPCSystem.PlayerStat_QuestsCompleted = h
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Spells Learned
	int i = Game.QueryStat("Spells Learned")
	if i > iNPCSystem.PlayerStat_SpellsLearned
		iNPCSystem.PlayerStat_SpellsLearned = i
		;Comment on magic if haven't already
	endif

	;Pockets Picked
	int j = Game.QueryStat("Pockets Picked")
	if j > iNPCSystem.PlayerStat_PocketsPicked
		iNPCSystem.PlayerStat_PocketsPicked = j
		iNPCSystem.IncreaseRegardMinor()
	endif

	;Locks Picked
	int k = Game.QueryStat("Locks Picked")
	if k > iNPCSystem.PlayerStat_LocksPicked
		iNPCSystem.PlayerStat_LocksPicked = k
		iNPCSystem.IncreaseRegardTiny()
		if randomfloat() < 0.25
			_Arissa_ReactionIndex.SetValueInt(3)
			_Arissa_Commentary_Reactions.Start()
		endif
	endif

	;Horses Stolen
	int l = Game.QueryStat("Horses Stolen")
	if l > iNPCSystem.PlayerStat_HorsesStolen
		iNPCSystem.PlayerStat_HorsesStolen = l
		iNPCSystem.IncreaseRegardMinor()
	endif

	;Dragon Souls Collected
	int n = Game.QueryStat("Dragon Souls Collected")
	if n > iNPCSystem.PlayerStat_DragonSoulsCollected
		iNPCSystem.PlayerStat_DragonSoulsCollected = n
		iNPCSystem.IncreaseRegardModerate()
		iNPCSystem.ArissaKnows_PlayerCanAbsorbDragonSouls = true
	endif

	;People Killed
	int o = Game.QueryStat("People Killed")
	if o > iNPCSystem.PlayerStat_PeopleKilled
		iNPCSystem.PlayerStat_PeopleKilled = o
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Undead Killed
	int p = Game.QueryStat("Undead Killed")
	if p > iNPCSystem.PlayerStat_UndeadKilled
		iNPCSystem.PlayerStat_UndeadKilled = p
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Daedra Killed
	int q = Game.QueryStat("Daedra Killed")
	if q > iNPCSystem.PlayerStat_DaedraKilled
		iNPCSystem.PlayerStat_DaedraKilled = q
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Automatons Killed
	int r = Game.QueryStat("Automatons Killed")
	if r > iNPCSystem.PlayerStat_AutomatonsKilled
		iNPCSystem.PlayerStat_AutomatonsKilled = r
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Times Shouted
	int s = Game.QueryStat("Times Shouted")
	if s > iNPCSystem.PlayerStat_TimesShouted
		iNPCSystem.PlayerStat_TimesShouted = s
		iNPCSystem.ArissaKnows_PlayerCanShout = true
		;Show off
	endif

	;Words Of Power Learned
	int t = Game.QueryStat("Words Of Power Learned")
	if t > iNPCSystem.PlayerStat_WordsOfPowerLearned
		iNPCSystem.PlayerStat_WordsOfPowerLearned = t
		iNPCSystem.IncreaseRegardTiny()
	endif

	;Sneak Attacks
	int u = Game.QueryStat("Sneak Attacks")
	if u > iNPCSystem.PlayerStat_SneakAttacks
		iNPCSystem.PlayerStat_SneakAttacks = u
		iNPCSystem.IncreaseRegardMinor()
	endif

	;Theft
	if iNPCSystem.ArissaKnows_PlayerSteals == false
		int y = Game.QueryStat("Items Stolen")
		if y > iNPCSystem.PlayerStat_ItemsStolen
			iNPCSystem.ArissaKnows_PlayerSteals = true
			iNPCSystem.IncreaseRegardModerate()
			_Arissa_ReactionIndex.SetValueInt(9)
			_Arissa_Commentary_Reactions.Start()
		endif
	endif

	;DECREASES
	;Assaults
	;Removed - problematic - shooting wildlife is considered "assault" sometimes
	;int v = Game.QueryStat("Assaults")
	;if v > iNPCSystem.PlayerStat_Assaults
	;	iNPCSystem.PlayerStat_Assaults = v
	;	iNPCSystem.DecreaseRegardMinor()
	;endif

	;Murders
	int w = Game.QueryStat("Murders")
	if w > iNPCSystem.PlayerStat_Murders
		iNPCSystem.PlayerStat_Murders = w
		iNPCSystem.DecreaseRegardExtreme()
		_Arissa_ReactionIndex.SetValueInt(8)
		_Arissa_Commentary_Reactions.Start()
	endif

	;Intimidations
	int x = Game.QueryStat("Intimidations")
	if x > iNPCSystem.PlayerStat_Intimidations
		iNPCSystem.PlayerStat_Intimidations = x
		iNPCSystem.DecreaseRegardMinor()
	endif

endFunction

function UpdateWaitState()
	float myRegard = iNPCSystem.PlayerAssessmentRegard
	;/if myRegard >= 5.0
		if iNPCSystem.WaitingQuestOverride == true
			iNPCSystem.CanWait = false
		else
			iNPCSystem.CanWait = true
		endif
	elseif myRegard < 5.0 && myRegard >= 0.0
		if iNPC.GetActorReference().GetCurrentLocation().HasKeyword(LocTypeDungeon)
			iNPCSystem.CanWait = false
		elseif iNPCSystem.WaitingQuestOverride == true
			iNPCSystem.CanWait = false
		else
			iNPCSystem.CanWait = true
		endif
	elseif myRegard < 0.0
		iNPCSystem.CanWait = false
	endif
	/;
	if myRegard >= -5.0 && iNPCSystem.WaitingQuestOverride == false
		iNPCSystem.CanWait = true
	else
		iNPCSystem.CanWait = false
	endif
endFunction

function UpdateFollowDistance()
	iNPCSystem.FollowDistance = 2
	;/if iNPC.GetActorReference().IsInInterior()
		iNPCSystem.FollowDistance = 2
	elseif iInTownRoamArea > -1
		iNPCSystem.FollowDistance = 3
	else
		iNPCSystem.FollowDistance = 2
	endif/;
endFunction

bool function CheckSocialCondition()
	;Determine if it is socially acceptable to relax here.
	Location myLoc = iNPC.GetActorRef().GetCurrentLocation()
	if myLoc && (myLoc.HasKeyword(LocTypeHouse) || myLoc.HasKeyword(LocTypePlayerHouse) || 		\
		           myLoc.HasKeyword(LocTypeInn) || myLoc.HasKeyword(LocTypeStore) || 			\
		           myLoc.HasKeyword(LocTypeTown) || myLoc.HasKeyword(LocTypeCastle) || 			\
		           myLoc.HasKeyword(LocTypeCity))
		return true
	else
		return false
	endif	
endFunction

function TryToGiveTheftResults()
	if iNPC.GetActorRef().GetDistance(PlayerRef) <= 300.0 && iNPCSystem.ArissaHasStolen == true && iNPCSystem.IsFollowing == true
		if iNPCSystem.ArissaTalkedAbout_TownTheft == true && iNPCSystem.PlayerWantsTheftMoney == true
			_Arissa_TheftQuestOngoingScene.Start()
			if Game.GetPlayer().GetLevel() >= 50
     			Game.GetPlayer().AddItem(Gold001, RandomInt(200, 400))
			elseif Game.GetPlayer().GetLevel() >= 40
     			Game.GetPlayer().AddItem(Gold001, RandomInt(150, 300))
			elseif Game.GetPlayer().GetLevel() >= 30
     			Game.GetPlayer().AddItem(Gold001, RandomInt(100, 250))
			elseif Game.GetPlayer().GetLevel() >= 20
     			Game.GetPlayer().AddItem(Gold001, RandomInt(50, 200))
			elseif Game.GetPlayer().GetLevel() >= 10
     			Game.GetPlayer().AddItem(Gold001, RandomInt(25, 100))
			else
     			Game.GetPlayer().AddItem(Gold001, RandomInt(13, 50))
			endif
			iNPCSystem.ArissaHasStolen = false
		endif
	endif
endFunction

function TryToDoThingsWhenPlayerNotLooking()
	;1.3: Disabled pending testing and rework
	;/
	if !PlayerRef.HasLOS(iNPC.GetActorRef())
		ArissaDebug(3, "Attempting to do things when player not looking!")
		;Do things when the player isn't looking
		if iNPC.GetActorRef().GetDistance(PlayerRef) > 1600.0 && iNPC.GetActorRef().GetDistance(PlayerRef) < 10000.0 && iNPCSystem.IsFollowing == true && iNPCSystem.IsWaiting == false && iNPCSystem.IsTownRoaming == false && PlayerRef.IsInInterior() == false
			;debug.trace("[Arissa] Jumping Arissa to player location.")
			Angle = 135.0 - Angle
			float TargetX = PlayerRef.GetPositionX() + OffsetX * math.sin(PlayerRef.GetAngleZ() + 30.0)
			float TargetY = PlayerRef.GetPositionY() + OffsetY * math.cos(PlayerRef.GetAngleZ() + 30.0)
			float TargetZ = PlayerRef.GetPositionZ() + OffsetZ
			iNPCSystem.iNPC.GetActorRef().TranslateTo(TargetX, TargetY, TargetZ, 0.0, 0.0, Angle, 3000.0, 0.0)
		endif
	endif
	/;
endfunction

function TryToSaySomethingAboutSurroundings()
	;Puzzle Doors
	ObjectReference PuzzleDoor = Game.FindClosestReferenceOfAnyTypeInListFromRef(PuzzleDoorKeyholes, PlayerRef, 750.0)
	if (PuzzleDoor)
		if (PuzzleDoor as HallofStoriesKeyholeScript).GetState() != "done"
			_Arissa_ReactionIndex.SetValueInt(6)
			_Arissa_Commentary_Reactions.Start()
			wait(3)
			iNPCSystem.ArissaKnows_SeenPuzzleDoorBefore = true
			iNPCSystem.Arissa_CommentedOn_PuzzleDoor = true
		else
			_Arissa_ReactionIndex.SetValueInt(4)
			_Arissa_Commentary_Reactions.Start()
			wait(3)
			iNPCSystem.Arissa_CommentedOn_PuzzleDoor = true
		endif
	endif

	;The Pale Blade
	ObjectReference PaleBlade = Game.FindClosestReferenceOfTypeFromRef(dunFrostmereCryptPaleBladeAct, PlayerRef, 500.0)
	if (PaleBlade)
		if PaleBlade.IsEnabled() && iNPCSystem.ArissaTalkedAbout_Weapon_PaleBlade == false && PlayerRef.GetCombatState() == 0
			_Arissa_ReactionIndex.SetValueInt(5)
			_Arissa_Commentary_Reactions.Start()
			wait(3)
			iNPCSystem.ArissaTalkedAbout_Weapon_PaleBlade = true
		endif
	endif

endFunction

function UpdateLongTermMood()
	;Check whether or not iNPC's mood is strong enough to shift permanently.
	;The iNPC's regard can limit how far this can permanently shift.

	;Assessment    		/       Possible Anchor Values 			 	/ Possible Default Moods
	;-20 -16 			/ -3 to 0 Openness, -3 to 0 Playfulness 	/ Standoff-ish
	;-15 -6				/ -3 to 0 Openness, -3 to 3 Playfulness 	/ Standoff-ish, Sarcastic
	;-5  4  			/ -3 to 3 Openness, -3 to 3 Playfulness 	/ Standoff-ish, Sarcastic, Caring, Flirty
	;5   20 			/  0 to 3 Openness, -3 to 3 Playfulness 	/ Caring, Flirty

	if iNPCSystem.AxisOpenness == 3
		iNPCSystem.AxisAnchorOpenness += 1
	elseif iNPCSystem.AxisOpenness == -3
		iNPCSystem.AxisAnchorOpenness -= 1
	endif

	if iNPCSystem.AxisPlayfulness == 3
		iNPCSystem.AxisAnchorPlayfulness += 1
	elseif iNPCSystem.AxisPlayfulness == -3
		iNPCSystem.AxisAnchorPlayfulness -= 1
	endif	
endFunction

function RegressMood()

	;Regress the iNPC's mood back toward the anchors.
	if iNPCSystem.AxisOpenness > iNPCSystem.AxisAnchorOpenness
		iNPCSystem.AxisOpenness -= 1
	elseif iNPCSystem.AxisOpenness < iNPCSystem.AxisAnchorOpenness
		iNPCSystem.AxisOpenness += 1
	endif

	if iNPCSystem.AxisPlayfulness > iNPCSystem.AxisAnchorPlayfulness
		iNPCSystem.AxisPlayfulness -= 1
	elseif iNPCSystem.AxisPlayfulness < iNPCSystem.AxisAnchorPlayfulness
		iNPCSystem.AxisPlayfulness += 1
	endif
endFunction

function ResetTempDialogueFlags()
	iNPCSystem.ArissaCommentedOn_Armor_Iron = false
	iNPCSystem.ArissaCommentedOn_Armor_Steel_1 = false
	iNPCSystem.ArissaCommentedOn_Armor_Steel_2 = false
	iNPCSystem.ArissaCommentedOn_Armor_Dwarven = false
	iNPCSystem.ArissaCommentedOn_Armor_Orcish = false
	iNPCSystem.ArissaCommentedOn_Armor_Ebony = false
	iNPCSystem.ArissaCommentedOn_Armor_Dragonbone = false
	iNPCSystem.ArissaCommentedOn_Armor_Leather = false
	iNPCSystem.ArissaCommentedOn_Armor_Bandit_1 = false
	iNPCSystem.ArissaCommentedOn_Armor_Bandit_2 = false
	iNPCSystem.ArissaCommentedOn_Armor_Scale = false
	iNPCSystem.ArissaCommentedOn_Armor_Imperial = false
	iNPCSystem.ArissaCommentedOn_Armor_Stormcloak = false
	iNPCSystem.ArissaCommentedOn_Armor_AncientNord = false
	iNPCSystem.Arissa_CommentedOn_PuzzleDoor = false
endFunction

function TryToSandboxAroundPlayer()
	; Arissa 2.2 - Check if player is playing music
	if (Compatibility.isBecomeABardLoaded) && (Compatibility._LP_BardIsPlaying.GetValueInt() == 1)
		ArissaDebug(1, "iNPC: Player is playing instrument in Become A Bard, don't sandbox.")
		return
	endif

	; cycle all positions down one notch in the history arrays
	int historyIndex = 0
	while (historyIndex < __historySize - 1)
		__playerPosX[historyIndex] = __playerPosX[historyIndex + 1]
		__playerPosY[historyIndex] = __playerPosY[historyIndex + 1]
		__playerPosZ[historyIndex] = __playerPosZ[historyIndex + 1]

		historyIndex += 1
	endwhile

	; set the most recent history as the current player position
	Actor _player = PlayerRef
	__playerPosX[__historySize - 1] = _player.X
	__playerPosY[__historySize - 1] = _player.Y
	__playerPosZ[__historySize - 1] = _player.Z


	; check current position against oldest history point if we're
	;   in follow mode
	if (iNPCSystem.IsFollowing)
		bool switchedPackageConditions = false

		if (!iNPCSystem.CanWait && iNPC.GetActorReference().GetActorValue("WaitingForPlayer") != 0)
			; she's not willing to wait for the player right now, but for
			;  some reason is waiting. Let's kick her out of this.
			iNPC.GetActorReference().SetActorValue("WaitingForPlayer", 0)
			switchedPackageConditions = true
		endif

		; calculate distance between history start and present
		;    sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
		float xFactor = (__playerPosX[0] - _player.X)
		xFactor = xFactor * xFactor
		float yFactor = (__playerPosY[0] - _player.Y)
		yFactor = yFactor * yFactor
		float zFactor = (__playerPosZ[0] - _player.Z)
		zFactor = zFactor * zFactor

		float distance = Math.sqrt(xFactor + yFactor + zFactor)

		; if the player has moved less than the defined settle radius,
		;   set the flag that the sandbox package is looking for.
		if (distance > SettleRadius)
			if (iNPCSystem.PlayerSettled == true)
				switchedPackageConditions = true
			endif
			iNPCSystem.PlayerSettled = false
		else
			if (iNPCSystem.PlayerSettled == false)
				switchedPackageConditions = true
			endif
			iNPCSystem.PlayerSettled = true
		endif

		; only do the EVP if we've actually changed the value
		if (switchedPackageConditions)
			if (iNPCSystem.PlayerSettled)
				ArissaDebug(1, "iNPC: Player settled; sandbox.")
			else
				ArissaDebug(1, "iNPC: Player moving more than settle radius; resume follow.")
			endif
			iNPC.GetActorReference().EvaluatePackage()
		endif
	endif
endFunction

function TryToRideHorse()
	; Credit to Alek (mitchalek@yahoo.com) of Convenient Horses for some enhancements.
	Actor ArissaRef = iNPC.GetActorRef()
	ArissaDebug(1, "Arissa Sit State: " + ArissaRef.GetSitState())
	if iNPCSystem.CanRideOwnHorse
		; Do not mount if knocked, bleeding out, swimming, falling, talking, synced, etc.
		if (!ArissaRef.IsOnMount() && ArissaRef.GetSitState() == 0) && PlayerRef.IsOnMount() && !ArissaRef.IsInCombat()
			if !ArissaRef.GetAnimationVariableBool("bVoiceReady")
				if !(ArissaRef.GetAnimationVariableBool("IsAttacking") || ArissaRef.GetAnimationVariableBool("IsCastingRight") || ArissaRef.GetAnimationVariableBool("IsCastingLeft"))
					return
				endif
			endif
			
			;summon horse
			ArissaDebug(1, "Trying to mount a horse.")
			if MyHorse == none
				MyHorse = ArissaRef.PlaceAtMe(iNPC_Horse)
				int i = 10
				while MyHorse.Is3DLoaded() == false && i > 0
					wait(0.5)
					i -= 1
				endwhile
			else
				if ArissaRef.GetDistance(MyHorse) > 2000.0
					MyHorse.Disable(true)
					MyHorse.Delete()
					MyHorse = none
					return
				endif
			endif

			iNPCSystem.IsRidingOwnHorse = true
			removed_torch_count = ArissaRef.GetItemCount(Torch01)
			ArissaRef.RemoveItem(Torch01, removed_torch_count)

			float ang_z
			MyHorse.Activate(ArissaRef, true)
			wait(0.5)
			int i = 4
			while !ArissaRef.IsOnMount() && ArissaRef.GetAnimationVariableBool("bVoiceReady") && i > 0
				ArissaDebug(1, "Arissa trying to mount horse...")
				ang_z = MyHorse.GetAngleZ() - 90
				ArissaRef.SetAngle(0, 0, ang_z + 180)
				ArissaRef.MoveTo(MyHorse, 60 * Sin(ang_z), 60 * Cos(ang_z), 0, false)
				MyHorse.Activate(ArissaRef, true)
				i -= 1
				wait(0.5)
			endwhile
		else
			; Dismount if in combat, if too far away from the horse (i.e. don't try to mount after fast travel) or player unmounted
			if ArissaRef.IsInCombat() || (MyHorse && ArissaRef.GetDistance(MyHorse) > 2000.0) || (!PlayerRef.IsOnMount() && ArissaRef.IsOnMount())
				;get rid of horse
				ArissaDebug(1, "Dismounting.")
				ArissaRef.Dismount()
				iNPCSystem.IsRidingOwnHorse = false
				wait(4.0)
				if MyHorse != none
					while (MyHorse as Actor).IsBeingRidden()
						wait(0.1)
					endwhile
					MyHorse.Disable(true)
					MyHorse.Delete()
					MyHorse = none
				endif
				ArissaRef.Additem(Torch01, removed_torch_count)
				removed_torch_count = 0
			else
				ArissaDebug(1, "Player and Arissa are currently mounted.")
			endif
		endif
	endif
endFunction

function CheckRegard()
	;Make sure player has Regard spell
	if !PlayerRef.HasSpell(_Arissa_RegardSpell)
		PlayerRef.AddSpell(_Arissa_RegardSpell, false)
	endif

	;Player consistently opposed
	if _Arissa_Regard.GetValue() <= -10.0
		if iNPCSystem.IsFollowing
			iNPCSystem.DisengageFollowBehavior()
		endif
	endif

	;Cannibalism
	if PlayerRef.HasMagicEffect(DA11AbFortifyHealth) || (Compatibility.IsImperiousLoaded && PlayerRef.HasMagicEffect(Compatibility.ImperiousYffresBlessing))
		if iNPCSystem.IsFollowing && iNPCSystem.iNPC.GetActorRef().HasLOS(PlayerRef)
			iNPCSystem.ArissaKnows_PlayerIsCannibal = true
			iNPCSystem.SlamToDisregarded()
			iNPCSystem.DisengageFollowBehavior()
		endif
	endif

	;Summon spell
	if _Arissa_Regard.GetValue() >= 8.0
		if !PlayerRef.HasSpell(_Arissa_SummonSpell)
			PlayerRef.AddSpell(_Arissa_SummonSpell)
		endif
	else
		if PlayerRef.HasSpell(_Arissa_SummonSpell)
			PlayerRef.RemoveSpell(_Arissa_SummonSpell)
		endif
	endif

endFunction

function ArissaDebug(int iClassification, string sDebugMessage)
	;1 = Regard updates, status changes
	;2 = Quest state data
	;3 = Scene data
	;4 = Other
	if _Arissa_DebugVar.GetValueInt() == iClassification
		debug.trace("[Arissa] " + sDebugMessage)
	endif
endFunction