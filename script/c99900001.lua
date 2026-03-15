-- Nikke Anis
-- ID: 99900001
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local ENCOUNTER_CARD_ID = 99900003

function s.initial_effect(c)
	-- 1. Search Spell (On Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- 2. Special Summon (With Encounter) - [Built-in / ไม่ต้อง Activate]
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SPSUMMON_PROC)
	e3:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e3:SetRange(LOCATION_HAND)
	-- จำกัด 1 ครั้งต่อเทิร์น (Ony 1 Special Summon this way per turn)
	e3:SetCountLimit(1,id) 
	e3:SetCondition(s.spcon_encounter)
	c:RegisterEffect(e3)
end

-- ==================================================================
-- Filters
-- ==================================================================
function s.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end

function s.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

-- ==================================================================
-- Logic 1: Search Spell
-- ==================================================================
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
-- Logic 2: Special Summon (Encounter) - Built-in
-- ==================================================================
function s.spcon_encounter(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- เช็ค: ช่องว่างต้องพอ และ มี Encounter บนสนาม
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end