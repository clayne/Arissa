;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname TIF__000D0320 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
Ammo practiceArrows
Int playerArrows
practiceArrows = (getOwningQuest() as dunArcherQuestScript).myAmmo
playerArrows = game.getPlayer().getItemCount(practiceArrows)
if(playerArrows >= 5)
	getOwningQuest().setStage(70)
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
