-- T-Class Rapture Chatterbox
-- ID: 99900205
local s,id=GetID()
local ID_RAPTURE = 0xc22

function s.initial_effect(c)
	-- กฎการอัญเชิญพิเศษ (Revive Limit)
	c:EnableReviveLimit()
	
	-- 1. Ignition: Destroy 1 Machine & 1 Rapture -> Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. On Summon Trigger (กลับมาใช้ SPSUMMON ตามปกติ)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- 3. Continuous: Gain ATK each time card is destroyed
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_MZONE)
	e4:SetOperation(s.atk_boost_op)
	c:RegisterEffect(e4)

	-- 4. Quick Effect: Negate Target/Destroy & Random Destroy
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCondition(s.negcon)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end

-- ==================================================================
-- Logic 1: Destroy -> Special Summon
-- ==================================================================
function s.pair_check(sg,e,tp)
	local cards = {}
	for tc in aux.Next(sg) do
		table.insert(cards, tc)
	end
	if #cards == 2 then
		local valid_pair = (cards[1]:IsRace(RACE_MACHINE) and cards[2]:IsSetCard(ID_RAPTURE))
						or (cards[2]:IsRace(RACE_MACHINE) and cards[1]:IsSetCard(ID_RAPTURE))
		return valid_pair and Duel.GetMZoneCount(tp,sg)>0
	end
	return false
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local c=e:GetHandler()
	local rg=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then 
		return c:IsCanBeSpecialSummoned(e,0,tp,true,true) and rg:CheckSubGroup(s.pair_check,2,2,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg=rg:SelectSubGroup(tp,s.pair_check,false,2,2,e,tp)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g_all=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if not g_all or not c:IsRelateToEffect(e) then return end
	local g=g_all:Filter(Card.IsRelateToEffect,nil,e)
	
	if #g==2 and Duel.Destroy(g,REASON_EFFECT)==2 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			-- [แก้กลับ] กลับมาใช้ Special Summon มาตรฐาน พร้อมทริคทะลวงกฎสุสาน (true, true)
			Duel.SpecialSummon(c,0,tp,tp,true,true,POS_FACEUP)
		end
	end
end

-- ==================================================================
-- Logic 2: On Summon -> Destroy or Buff (ATK +900)
-- ==================================================================
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local c=e:GetHandler()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Destroy(tc,REASON_EFFECT)==0 then
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(900)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e1)
			end
		end
	end
end

-- ==================================================================
-- Logic 3: ATK Boost when card destroyed (Stacking 200)
-- ==================================================================
function s.atk_boost_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
	if ct>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*200)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end

-- ==================================================================
-- Logic 4: Negate & Random Destroy (Only On Field)
-- ==================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- เช็คว่าตัวมันเองต้องหงายหน้าอยู่ และอีกฝ่ายเป็นคนใช้เอฟเฟค
	if not c:IsFaceup() or rp==tp then return false end
	
	-- กรณีที่ 1: เช็คว่าตัวมันเองตกเป็น "เป้าหมาย (Target)" หรือไม่
	if re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if tg and tg:IsContains(c) then return true end
	end
	
	-- กรณีที่ 2: เช็คว่าเอฟเฟคนั้นจะ "ทำลาย" ตัวมันเองหรือไม่
	if re:IsHasCategory(CATEGORY_DESTROY) then
		local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
		-- ถ้ากลุ่มเป้าหมายที่จะถูกทำลาย (tg) มีตัวมันเอง (c) อยู่ในนั้นด้วย
		if ex and tg~=nil and tg:IsContains(c) then return true end
	end
	
	return false
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
		if #g>0 then
			Duel.BreakEffect()
			local sg=g:RandomSelect(tp,1)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end