-- L-Class Rapture Cucumber
-- ID: 99900202
local s,id=GetID()
local ID_RAPTURE = 0xc22

function s.initial_effect(c)
	-- 1. Ignition: Normal Summon Self (Extra + No Tribute) + Extra Deck Lock
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- HOPT 1
	e1:SetTarget(s.nstg)
	e1:SetOperation(s.nsop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Opponent activates Monster Effect -> Send Lv5+ Machine -> Summon Self (Hand/GY)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE+CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100) -- HOPT 2
	e2:SetCondition(s.react_con)
	e2:SetTarget(s.react_tg)
	e2:SetOperation(s.react_op)
	c:RegisterEffect(e2)
end

-- ==================================================================
-- Logic 1: Extra Normal Summon + Restriction
-- ==================================================================
function s.nstg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsSummonableCard()
	end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,c,1,0,0)
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Normal Summon (Ignore Count)
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SUMMON_PROC)
		e1:SetCondition(s.ntcon_temp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		
		Duel.Summon(tp,c,true,nil)
	end
	
	-- 2. Apply Restriction
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,2)) 
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

function s.ntcon_temp(e,c,minc)
	if c==nil then return true end
	return minc==0 and c:GetLevel()>4 and Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	local is_fsl = c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_LINK)
	return c:IsLocation(LOCATION_EXTRA) and is_fsl and not c:IsSetCard(ID_RAPTURE)
end

-- ==================================================================
-- Logic 2: Opponent Effect -> Send Lv5+ Machine -> Summon Self
-- ==================================================================
function s.react_con(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	local is_main = (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and is_main
end

function s.dump_filter(c)
	return c:IsRace(RACE_MACHINE) and c:IsLevelAbove(5) and c:IsAbleToGrave()
end

function s.react_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.dump_filter,tp,LOCATION_DECK,0,1,nil)
		   and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		   and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.react_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.dump_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,SUMMON_TYPE_NORMAL,tp,tp,false,false,POS_FACEUP)
		end
	end
end