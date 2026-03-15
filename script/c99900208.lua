-- T-Class Rapture Alteisen
-- ID: 99900208
local s,id=GetID()
local ID_RAPTURE = 0xc22
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	-- กฎการอัญเชิญพิเศษ (Synchro Summon ไม่ได้)
	c:EnableReviveLimit()
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE) -- ห้าม Synchro Summon ลงมาปกติ
	c:RegisterEffect(e0)

	-- 1. Ignition: Destroy 1 Machine & 1 Rapture -> Special Summon from Extra/GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_EXTRA+LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Continuous: Gain ATK each time a card(s) is destroyed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.atk_boost_op)
	c:RegisterEffect(e2)

	-- 3. Quick Effect (Extra Deck): Opponent 5+ Actions -> Dump & Destroy
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetRange(LOCATION_EXTRA)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.trcon)
	e3:SetTarget(s.trtg)
	e3:SetOperation(s.trop)
	c:RegisterEffect(e3)

	-- 4. Ignition (Field): Discard 1 -> Destroy 1 card on the field
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- ==================================================================
	-- Global System: นับแอคชั่น (Special Summon หรือ Monster Effect บนสนาม)
	-- ==================================================================
	if not s.global_check then
		s.global_check = true
		local ge1 = Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop_sp)
		Duel.RegisterEffect(ge1, 0)
		
		local ge2 = Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_CHAINING)
		ge2:SetOperation(s.checkop_ch)
		Duel.RegisterEffect(ge2, 0)
	end
end

-- ==================================================================
-- Logic 1: Summon
-- ==================================================================
function s.pair_check(sg,e,tp)
	local cards = {}
	for tc in aux.Next(sg) do table.insert(cards, tc) end
	if #cards == 2 then
		local valid_pair = (cards[1]:IsRace(RACE_MACHINE) and cards[2]:IsSetCard(ID_RAPTURE))
						or (cards[2]:IsRace(RACE_MACHINE) and cards[1]:IsSetCard(ID_RAPTURE))
		local c=e:GetHandler()
		if c:IsLocation(LOCATION_EXTRA) then
			return valid_pair and Duel.GetLocationCountFromEx(tp,tp,sg,c)>0
		else
			return valid_pair and Duel.GetMZoneCount(tp,sg)>0
		end
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
		Duel.SpecialSummon(c,0,tp,tp,true,true,POS_FACEUP)
	end
end

-- ==================================================================
-- Logic 2: ATK Boost when card destroyed
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
-- Logic 3: Global Counter & Extra Deck Quick Effect (Dump + Destroy)
-- ==================================================================
function s.checkop_sp(e,tp,eg,ep,ev,re,r,rp)
	local p0_sum = false
	local p1_sum = false
	for tc in aux.Next(eg) do
		if tc:IsSummonType(SUMMON_TYPE_SPECIAL) then
			if tc:GetSummonPlayer()==0 then p0_sum = true end
			if tc:GetSummonPlayer()==1 then p1_sum = true end
		end
	end
	if p0_sum then Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1) end
	if p1_sum then Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1) end
end

function s.checkop_ch(e,tp,eg,ep,ev,re,r,rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	-- [แก้ไข] เช็คว่าเป็นเอฟเฟคมอนสเตอร์ และอยู่บนสนามเท่านั้น
	if re:IsActiveType(TYPE_MONSTER) and loc==LOCATION_MZONE then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

function s.trcon(e,tp,eg,ep,ev,re,r,rp)
	local ph = Duel.GetCurrentPhase()
	if ph ~= PHASE_MAIN1 and ph ~= PHASE_MAIN2 then return false end
	return Duel.GetFlagEffect(1-tp,id) >= 5
end

function s.dump_filter(c)
	return (c:IsSetCard(ID_RAPTURE) or c:IsSetCard(ID_HERETIC)) and c:IsAbleToGrave()
end

function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then 
		return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
		   and Duel.IsExistingMatchingCard(s.dump_filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.trop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.dump_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)>0 then
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.Destroy(tc,REASON_EFFECT)
		end
	end
end

-- ==================================================================
-- Logic 4: Discard 1 -> Destroy 1 card (Field Ignition)
-- ==================================================================
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end