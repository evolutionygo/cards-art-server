-- Mass-Produced Heretic Nikke
-- ID: 99900042
local s,id=GetID()
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	-- Ritual Monster Setup
	c:EnableReviveLimit()

	-- 1. Treated as "Heretic" while on field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetValue(ID_HERETIC)
	c:RegisterEffect(e1)

	-- 2. Ritual Summon Procedure (Ignition: Send from Deck -> SS)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE+CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id) -- Hard 1 Turn
	e2:SetTarget(s.rittg)
	e2:SetOperation(s.ritop)
	c:RegisterEffect(e2)

	-- 3. On Summon -> Search "Heretic" Card (Hard 1 Turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id+100) -- Hard 1 Turn
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
	
	local e4=e3:Clone()
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- 4. Hand/Deck to GY -> Dump Machine & Random Banish Opponent's Deck/GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DECKDES+CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	-- Unlimited use (No CountLimit)
	e5:SetCondition(s.gycon)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
	c:RegisterEffect(e5)
end

-- ==================================================================
-- Logic 2: Ritual Summon Procedure
-- ==================================================================
function s.dumpfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsDefenseBelow(1600) and not c:IsCode(id) and c:IsAbleToGrave()
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
		and Duel.IsExistingMatchingCard(s.dumpfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.dumpfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
			c:CompleteProcedure()
		end
	end
end

-- ==================================================================
-- Logic 3: Search Heretic
-- ==================================================================
function s.thfilter(c)
	return c:IsSetCard(ID_HERETIC) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ==================================================================
-- Logic 4: Dump & Random Banish (Deck/GY)
-- ==================================================================
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND) or c:IsPreviousLocation(LOCATION_DECK)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dumpfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Send Machine to GY (Cost-like Effect)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.dumpfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		
		-- 2. Random Banish 1 from Opponent's Deck or GY
		local g_deck = Duel.GetFieldGroup(tp,0,LOCATION_DECK)
		local g_gy = Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
		g_deck:Merge(g_gy) -- Combine Deck and GY
		
		if #g_deck > 0 then
			-- Random Select 1
			local sg = g_deck:RandomSelect(tp,1)
			-- Banish Face-down
			Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
		end
	end
end