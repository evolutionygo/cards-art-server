-- Nikke Neon
-- ID: 99900002
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local ENCOUNTER_CARD_ID = 99900003

function s.initial_effect(c)
	-- 1. Special Summon from Hand (Built-in)
	-- กำหนดให้การลงวิธีนี้มีค่า Summon Type พิเศษ (+1)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon_main)
	e1:SetValue(SUMMON_TYPE_SPECIAL+1) -- <--- กุญแจสำคัญ: แปะป้ายว่าลงด้วยวิธีนี้
	c:RegisterEffect(e1)

	-- 2. Send to GY (Mandatory Trigger)
	-- "บังคับส่ง" แต่เช็คเงื่อนไขว่าต้องมาจากวิธีข้างบนเท่านั้น
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1)) 
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) -- Forced (บังคับ)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.tgcon) -- <--- เช็คว่าลงมาด้วยท่าไหน
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)

	-- 3. SS from Deck (With Encounter) - [Optional / เลือกได้]
	-- เอฟเฟคนี้ยังทำงานได้กับการอัญเชิญทุกแบบ (ถ้ามี Encounter)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id+2)
	e3:SetCondition(s.spcon_deck)
	e3:SetTarget(s.sptg_deck)
	e3:SetOperation(s.spop_deck)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- Logic 1: Built-in Special Summon
-- ==================================================================
function s.spcon_main(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.faceup_nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

-- ==================================================================
-- Logic 2: Send to GY (Specific Trigger)
-- ==================================================================
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	-- เช็ค: ฉันถูกอัญเชิญมาด้วยท่าพิเศษ (+1) ใช่หรือไม่?
	-- ถ้าโดนชุบด้วย Monster Reborn ค่านี้จะเป็น SUMMON_TYPE_SPECIAL เฉยๆ เงื่อนไขจะไม่ผ่าน
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL+1)
end

function s.tgfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- บังคับทำงาน (Forced)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- ==================================================================
-- Logic 3: SS from Deck (With Encounter)
-- ==================================================================
function s.faceup_nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end
function s.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end
function s.spcon_deck(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.spfilter_deck(c,e,tp)
	return c:IsSetCard(NIKKE_SET_ID) and c:GetAttack()<=1500 and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg_deck(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter_deck,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop_deck(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter_deck,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end