;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname _Arissa_Frag_MQ102_BalgruufPrisoner Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
if (MainQuest as _Arissa_iNPC_Behavior).IsFollowingAndNearPlayer()
    (MainQuest as _Arissa_iNPC_Behavior).ArissaPresentWhen_MQ102_PlayerAdmitsBeingPrisoner = true
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MainQuest  Auto  

Actor Property PlayerRef  Auto  
