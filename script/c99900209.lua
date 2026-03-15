-- T-Class Rapture Mother Whale
-- ID: 99900209
local s,id=GetID()
local ID_RAPTURE = 0xc22
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	-- กฎการอัญเชิญพิเศษ (Fusion Summon ไม่ได้)
	c:EnableReviveLimit()
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE) -- ห้ามอัญเชิญฟิวชั่นตามปกติ
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

	-- 3. Quick Effect (Extra Deck): Opponent 5+ Special Summons -> Dump & SS from Deck/GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetRange(LOCATION_EXTRA)
	e3:SetCountLimit(1,id) -- HOPT 1
	e3:SetCondition(s.trcon)
	e3:SetTarget(s.trtg)
	e3:SetOperation(s.trop)
	c:RegisterEffect(e3)

	-- 4. Trigger (Field): When card(s) destroyed -> SS from Hand/GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100) -- HOPT 2
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- ==================================================================
	-- Global System: นับจำนวนการ Special Summon ของอีกฝ่าย
	-- ==================================================================
	if not s.global_check then
		s.global_check = true
		local ge1 = Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop_sp)
		Duel.RegisterEffect(ge1, 0)
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
-- Logic 3: Global Counter & Extra Deck Quick Effect (Dump + SS)
-- ==================================================================
function s.checkop_sp(e,tp,eg,ep,ev,re,r,rp)
	local p0_sum = false
	local p1_sum = false
	for tc in aux.Next(eg) do
		-- นับเฉพาะการอัญเชิญพิเศษ
		if tc:GetSummonPlayer()==0 then p0_sum = true end
		if tc:GetSummonPlayer()==1 then p1_sum = true end
	end
	if p0_sum then Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1) end
	if p1_sum then Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1) end
end

function s.trcon(e,tp,eg,ep,ev,re,r,rp)
	local ph = Duel.GetCurrentPhase()
	-- [แก้ไข] เช็ค Main Phase และ อีกฝ่ายอัญเชิญพิเศษครบ 5 ครั้งขึ้นไป
	return (ph == PHASE_MAIN1 or ph == PHASE_MAIN2) and Duel.GetFlagEffect(1-tp,id) >= 5
end

function s.dump_filter(c)
	return (c:IsSetCard(ID_RAPTURE) or c:IsSetCard(ID_HERETIC)) and c:IsAbleToGrave()
end

function s.sp_filter1(c,e,tp)
	-- มอนสเตอร์เลเวล 5 หรือต่ำกว่า, เครื่องจักร หรือ ธาตุมืด
	return c:IsLevelBelow(5) and (c:IsRace(RACE_MACHINE) or c:IsAttribute(ATTRIBUTE_DARK)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.dump_filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	-- โอกาสอัญเชิญพิเศษจาก Deck หรือ GY
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.trop(e,tp,eg,ep,ev,re,r,rp)
	-- ส่งเข้าสุสานก่อน
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.dump_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)>0 then
		-- แล้วเด้งถามว่าจะอัญเชิญไหม
		local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.sp_filter1),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
		if #g2>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g2:Select(tp,1,1,nil)
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- ==================================================================
-- Logic 4: Field Trigger (When card destroyed -> SS from Hand/GY)
-- ==================================================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	-- เช็คว่ามีการ์ดบนสนามถูกทำลายจริงๆ
	return eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_ONFIELD)
end

function s.sp_filter2(c,e,tp)
	-- มอนสเตอร์เลเวล 5 หรือต่ำกว่า, เครื่องจักร หรือ ธาตุมืด (หาจากมือ/สุสาน)
	return c:IsLevelBelow(5) and (c:IsRace(RACE_MACHINE) or c:IsAttribute(ATTRIBUTE_DARK)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		   and Duel.IsExistingMatchingCard(s.sp_filter2,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.sp_filter2),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end