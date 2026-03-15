-- L-Class Rapture Thermite
-- ID: 99900200
local s,id=GetID()
local ID_RAPTURE = 0xc22

function s.initial_effect(c)
	-- 1. Ignition: Normal Summon Self (Extra + No Tribute) + Extra Deck Lock (Fusion, Synchro, Link)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- HOPT
	e1:SetTarget(s.nstg)
	e1:SetOperation(s.nsop)
	c:RegisterEffect(e1)

	-- 2. Search Level 5+ Machine OR Rapture S/T & Dump Machine
	-- (Unlimited Use)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
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
	
	-- 1. Normal Summon
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SUMMON_PROC)
		e1:SetCondition(s.ntcon_temp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		
		-- ตัวแปร true หมายถึง Ignore Extra Summon Count (ไม่นับโควต้า)
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
-- Logic 2: Search Level 5+ Machine OR Rapture S/T -> Dump Machine
-- ==================================================================
function s.thfilter(c)
	local is_machine_lv5 = c:IsLevelAbove(5) and c:IsRace(RACE_MACHINE)
	local is_rapture_st = c:IsSetCard(ID_RAPTURE) and c:IsType(TYPE_SPELL+TYPE_TRAP)
	return (is_machine_lv5 or is_rapture_st) and c:IsAbleToHand()
end

function s.dumpfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsAbleToGrave()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		   and Duel.IsExistingMatchingCard(s.dumpfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 then
		if Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g1)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local g2=Duel.SelectMatchingCard(tp,s.dumpfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #g2>0 then
				Duel.BreakEffect()
				Duel.SendtoGrave(g2,REASON_EFFECT)
			end
		end
	end
end