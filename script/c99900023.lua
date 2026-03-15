-- Fixer Nikke Sugar
-- ID: 99900023
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local TOKEN_ID = 99900026

function s.initial_effect(c)
	-- Synchro Summon Procedure
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(s.matfilter),1,99)

	-- 1. Cannot be targeted
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- 2. Tribute Opponent Monster & Spawn Token (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	-- ย้ายการสังเวยไปไว้ที่ Cost
	e2:SetCost(s.rmcost) 
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)

	-- 3. Leave Field -> Shuffle Back
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
end

function s.matfilter(c)
	return c:IsSetCard(NIKKE_SET_ID)
end

-- =======================================================================
-- [Effect 2] Kaiju Style Removal (Fixed Logic)
-- =======================================================================

function s.tributefilter(c,tp)
	-- เช็คว่าสังเวยได้ไหม (IsReleasable) และต้องสังเวยให้เราเป็นคนจ่าย (REASON_COST)
	return c:IsReleasable(REASON_COST) and not c:IsCode(TOKEN_ID) 
		and (Duel.GetMZoneCount(1-tp,c,tp)>0) -- เช็คว่าถ้าสังเวยตัวนี้ไป จะมีช่องว่างให้ Token ลงไหม
end

function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- [CHK=0] มีมอนสเตอร์ให้สังเวยไหม
	if chk==0 then return Duel.IsExistingMatchingCard(s.tributefilter,tp,0,LOCATION_MZONE,1,nil,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	-- เลือกสังเวย
	local g=Duel.SelectMatchingCard(tp,s.tributefilter,tp,0,LOCATION_MZONE,1,1,nil,tp)
	-- สั่งสังเวยด้วย REASON_COST (เคารพกฎห้ามสังเวย)
	Duel.Release(g,REASON_COST)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- [CHK=0] เช็คว่าเสก Token ได้ไหม (ไม่ต้องเช็คช่องว่างแล้ว เพราะเช็คเผื่อใน Cost แล้ว)
	if chk==0 then 
		return Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ID,0,TYPE_TOKEN+TYPE_MONSTER,0,500,1,RACE_MACHINE,ATTRIBUTE_DARK,POS_FACEUP_DEFENSE,1-tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	-- ตอนนี้เหลือแค่เสก Token เพราะการสังเวยทำไปแล้วใน Cost
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 
	   and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ID,0,TYPE_TOKEN+TYPE_MONSTER,0,500,1,RACE_MACHINE,ATTRIBUTE_DARK,POS_FACEUP_DEFENSE,1-tp) then
		
		local token=Duel.CreateToken(tp,TOKEN_ID)
		Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
	end
end

-- =======================================================================
-- [Effect 3] Leave Field -> Shuffle Back
-- =======================================================================
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsAbleToDeck() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		local g=Group.FromCards(tc)
		if c:IsAbleToDeck() or c:IsLocation(LOCATION_EXTRA) then
			g:AddCard(c)
		end
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end