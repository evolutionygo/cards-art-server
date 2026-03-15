-- Nikke Rapi: Red Hood
-- ID: 99900006
local s,id=GetID()
local RAPI_BASE_ID = 99900000
local RED_HOOD_ACTIVATION_ID = 99900005 -- หรือ Fusion เดิม
local GODDESS_RED_HOOD_ID = 99900031	-- Link Monster ใหม่

function s.initial_effect(c)
	-- 0. Summon Limit (Must be SS by Red Hood Activation OR Goddess Red Hood)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Excavate 3 (On Special Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.exctg)
	e1:SetOperation(s.excop)
	c:RegisterEffect(e1)

	-- 2. Pay 1500 LP -> Destroy 1 Monster (Cannot be Responded)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- 3. Battle Immunity
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- 4. Floating Effect (Sent to GY by card effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCondition(s.spcon_float)
	e4:SetTarget(s.sptg_float)
	e4:SetOperation(s.spop_float)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- Logic 0: Summon Limit (แก้ตรงนี้!)
-- ==================================================================
function s.splimit(e,se,sp,st)
	local sc = se:GetHandler()
	-- ยอมรับการเรียกจาก Activation (99900005) หรือ Link Monster (99900031)
	return sc:IsCode(RED_HOOD_ACTIVATION_ID) or sc:IsCode(GODDESS_RED_HOOD_ID)
end

-- ==================================================================
-- Logic 1: Excavate
-- ==================================================================
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_ATOHAND)
		-- ให้ฝ่ายตรงข้ามเลือก (1-tp)
		local sg=g:Select(1-tp,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			Duel.ShuffleHand(tp) -- สับการ์ดในมือ (Optional แต่ใส่ไว้ก็ดี)
		end
	end
	Duel.ShuffleDeck(tp) -- สับเด็คส่วนที่เหลือ
end

-- ==================================================================
-- Logic 2: Snipe Monster
-- ==================================================================
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1500) end
	Duel.PayLPCost(tp,1500)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	-- แจ้งว่าจะทำลาย 1 ใบ
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
	Duel.SetChainLimit(s.chainlm) -- ห้ามเชน
end

function s.chainlm(e,rp,tp)
	return false -- ห้ามตอบโต้ทุกกรณี
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- เลือกทำลาย
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- ==================================================================
-- Logic 4: Floating
-- ==================================================================
function s.spcon_float(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ต้องออกจากสนามลงสุสาน และต้องโดนส่งด้วยเอฟเฟคการ์ด
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsReason(REASON_EFFECT)
end

function s.spfilter(c,e,tp)
	return c:IsCode(RAPI_BASE_ID) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg_float(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.spop_float(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end