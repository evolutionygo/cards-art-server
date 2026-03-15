-- L-Class Rapture Vulcan R
-- ID: 99900201
local s,id=GetID()
local ID_RAPTURE = 0xc22

function s.initial_effect(c)
	-- 1. Ignition: Normal Summon Self (Extra + No Tribute) + Extra Deck Lock
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- HOPT 1 (จำกัดการกดใช้งานจากบนมือ)
	e1:SetTarget(s.nstg)
	e1:SetOperation(s.nsop)
	c:RegisterEffect(e1)

	-- 2. Trigger Effect: From Hand/Deck to GY -> Send Lv5+ Machine -> Add Lv5 Machine/DARK OR Rapture S/T
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.gycon)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
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
-- Logic 2: Hand/Deck to GY -> Dump & Search
-- ==================================================================
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND+LOCATION_DECK)
end

function s.gy_dump_filter(c)
	return c:IsRace(RACE_MACHINE) and c:IsLevelAbove(5) and not c:IsCode(id) and c:IsAbleToGrave()
end

function s.gy_th_filter(c)
	local is_mon = c:IsLevel(5) and (c:IsRace(RACE_MACHINE) or c:IsAttribute(ATTRIBUTE_DARK)) and c:IsType(TYPE_MONSTER)
	local is_rapture_st = c:IsSetCard(ID_RAPTURE) and c:IsType(TYPE_SPELL+TYPE_TRAP)
	return (is_mon or is_rapture_st) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.gy_dump_filter,tp,LOCATION_DECK,0,1,nil)
		   and Duel.IsExistingMatchingCard(s.gy_th_filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g_dump=Duel.SelectMatchingCard(tp,s.gy_dump_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g_dump>0 and Duel.SendtoGrave(g_dump,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g_th=Duel.SelectMatchingCard(tp,s.gy_th_filter,tp,LOCATION_DECK,0,1,1,nil)
		if #g_th>0 then
			Duel.BreakEffect()
			Duel.SendtoHand(g_th,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g_th)
		end
	end
end