-- Nikke Rapi
-- ID: 99900000
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local ENCOUNTER_CARD_ID = 99900003

function s.initial_effect(c)
	-- 1. Special Summon from Hand (No Nikke) [Built-in]
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon_empty)
	c:RegisterEffect(e1)

	-- 2. Special Summon from Grave (No Nikke) [Ignition]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0)) 
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon_empty_gy)
	e2:SetTarget(s.sptg_gy)
	e2:SetOperation(s.spop_gy)
	c:RegisterEffect(e2)

	-- 3. Search Effect (On Summon)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- 4. Special Summon from Hand (With Encounter) [Built-in]
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2)) 
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_SPSUMMON_PROC)
	e5:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e5:SetRange(LOCATION_HAND)
	e5:SetCountLimit(1,id+100)
	e5:SetCondition(s.spcon_encounter)
	c:RegisterEffect(e5)
end

-- Filters
function s.faceup_nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function s.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end

-- Logic: SS from Hand (No Nikke)
function s.spcon_empty(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and not Duel.IsExistingMatchingCard(s.faceup_nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

-- Logic: SS from Grave (No Nikke)
function s.spcon_empty_gy(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.faceup_nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg_gy(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop_gy(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Logic: Searcher (Updated: Cannot search itself)
function s.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsLevelBelow(4) and c:IsType(TYPE_MONSTER) 
		and c:IsAbleToHand() 
		and not c:IsCode(id) -- [NEW] ห้ามเป็น Rapi (id ตัวเอง)
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

-- Logic: SS from Hand (With Encounter)
function s.spcon_encounter(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end