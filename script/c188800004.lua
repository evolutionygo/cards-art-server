-- Brave Blade - Fuzetsu
-- ID: 188800004
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  

function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e0)

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON+CATEGORY_TODECK+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE) 
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.hand_con)
	e1:SetTarget(s.pen_tg)
	e1:SetOperation(s.pen_op)
	c:RegisterEffect(e1)

	-- วางลงสนามจากเด็ค
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_DECK)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.place_con)
	e2:SetTarget(s.place_tg)
	e2:SetOperation(s.place_op)
	c:RegisterEffect(e2)

	-- [CONTINUOUS EFFECTS]
	-- 1. บัพพลัง +200 x แบนิช
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_SZONE) 
	e3:SetTargetRange(LOCATION_MZONE,0) 
	e3:SetTarget(s.bb_tg) 
	e3:SetValue(s.atk_val)
	c:RegisterEffect(e3)

	-- 2. [อัปเดต] Continuous Effect ดักการ์ดขึ้นมือ (ไม่เข้าเชน)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_TO_HAND)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.todeck_con)
	e4:SetOperation(s.todeck_op)
	c:RegisterEffect(e4)

	-- 3. ล็อคเอฟเฟคมอนสเตอร์บนมือ/สุสาน
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_ACTIVATE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_SZONE) 
	e5:SetTargetRange(0,1)
	e5:SetValue(s.aclimit)
	c:RegisterEffect(e5)

	-- Maintenance Cost / End Phase
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e6:SetRange(LOCATION_SZONE) 
	e6:SetCountLimit(1)
	e6:SetOperation(s.mtop)
	c:RegisterEffect(e6)

	-- Redirect Banish
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e7:SetCondition(s.redirect_con)
	e7:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e7)
end

-- ==================================================================
-- [Shared Logic]
-- ==================================================================
function s.has_free_pzone(tp)
	return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
end

function s.controls_only_bb(tp)
	local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	if #g==0 then return false end
	
	local has_bb_monster = false
	for tc in aux.Next(g) do
		if tc:IsFaceup() and not tc:IsSetCard(ID_ARCHETYPE) then return false end
		if tc:IsFaceup() and tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) then has_bb_monster = true end
	end
	return has_bb_monster
end

function s.is_empty_or_only_bb_st(tp, c)
	local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	if c and g:IsContains(c) then g:RemoveCard(c) end
	if g:IsExists(Card.IsType, 1, nil, TYPE_MONSTER) then return false end
	if g:IsExists(function(tc) return tc:IsFaceup() and not tc:IsSetCard(ID_ARCHETYPE) end, 1, nil) then return false end
	return true
end

-- ==================================================================
-- [Hand Effect Logic]
-- ==================================================================
function s.hand_con(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.pen_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		if not s.has_free_pzone(tp) then return false end

		local c = e:GetHandler()
		local is_eff1 = s.is_empty_or_only_bb_st(tp, c)
		if is_eff1 then
			return Duel.IsExistingMatchingCard(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) end, tp, LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE, 0, 1, nil)
		else
			return Duel.IsExistingMatchingCard(s.non_bb_filter,tp,LOCATION_DECK,0,1,nil)
		end
	end

	local c = e:GetHandler()
	local e_banish = Effect.CreateEffect(c)
	e_banish:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e_banish:SetCode(EVENT_CHAIN_END)
	e_banish:SetLabelObject(c)
	e_banish:SetOperation(s.hand_banish_op)
	e_banish:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e_banish, tp)
end

function s.hand_banish_op(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetLabelObject()
	if c and (c:IsLocation(LOCATION_ONFIELD) or c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_HAND)) then
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	end
	e:Reset()
end

function s.bb_monster_filter(c)
	return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.non_bb_filter(c)
	return not c:IsSetCard(ID_ARCHETYPE) and c:IsAbleToHand()
end

function s.pen_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local is_eff1 = s.is_empty_or_only_bb_st(tp, c)
	
	if is_eff1 then
		local hand_bb = Duel.GetMatchingGroup(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) end, tp, LOCATION_HAND, 0, nil)
		if #hand_bb > 0 then
			Duel.SendtoDeck(hand_bb, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
			Duel.BreakEffect()
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local thg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.bb_monster_filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #thg>0 and Duel.SendtoHand(thg,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,thg)
			local tc=thg:GetFirst()
			if tc:IsLocation(LOCATION_HAND) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DECREASE_TRIBUTE)
				e1:SetValue(0x30003) 
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				
				if tc:IsSummonable(true,nil) then
					Duel.BreakEffect()
					Duel.Summon(tp,tc,true,nil) 
				end
			end
		end
	else
		if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND) then
			Duel.SendtoDeck(c, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
			Duel.BreakEffect()
		end
		local deck=Duel.GetMatchingGroup(s.non_bb_filter,tp,LOCATION_DECK,0,nil)
		if #deck>0 then
			local rand=deck:RandomSelect(tp,1)
			Duel.SendtoHand(rand,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,rand)
		end
	end
	
	if c:IsRelateToEffect(e) then
		c:CancelToGrave() 
		Duel.SendtoDeck(c,nil,2,REASON_EFFECT)
	end
end

-- ==================================================================
-- [Card Logic: Place from Deck to Spell/Trap Zone]
-- ==================================================================
function s.place_con(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) and s.controls_only_bb(tp)
end

function s.place_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local has_safe_zone = false
		for i=1,3 do
			if Duel.CheckLocation(tp,LOCATION_SZONE,i) then
				has_safe_zone = true
			end
		end
		return has_safe_zone
	end
end

function s.place_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true,0xe)
end

-- ==================================================================
-- [Continuous Logic & Redirect]
-- ==================================================================
function s.bb_tg(e,c)
	return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER)
end

function s.banished_bb_filter(c)
	return c:IsFaceup() and c:IsSetCard(ID_ARCHETYPE)
end

function s.atk_val(e,c)
	local count = Duel.GetMatchingGroupCount(s.banished_bb_filter,e:GetHandlerPlayer(),LOCATION_REMOVED,0,nil)
	return count * 200
end

-- [อัปเดตฟังก์ชันดักจับ] แบบไม่เปิดเชน (Continuous)
function s.todeck_filter(c,tp)
	return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED) and not (c:GetReason() & REASON_DRAW ~= 0)
end

function s.todeck_con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.todeck_filter,1,nil,tp)
end

function s.todeck_op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id) -- โชว์ไอคอนการ์ดให้รู้ว่าทำไมถึงโดนสับ
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TODECK)
		local sg=g:Select(1-tp,1,1,nil)
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_RULE) -- ใช้ REASON_RULE เพื่อความเด็ดขาด
	end
end

function s.aclimit(e,re,tp)
	local opp = 1 - e:GetHandlerPlayer()
	if tp == opp then
		return re:IsActiveType(TYPE_MONSTER) and not re:GetHandler():IsOnField()
	end
	return false
end

-- ==================================================================
-- [Maintenance Cost / Redirect Logic]
-- ==================================================================
function s.bb_mon_filter(c)
	return c:IsFaceup() and c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER)
end

function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local has_bb_mon = Duel.IsExistingMatchingCard(s.bb_mon_filter,tp,LOCATION_MZONE,0,1,nil)
	
	if has_bb_mon and Duel.CheckLPCost(tp,1000) then
		if Duel.SelectEffectYesNo(tp, c) then
			Duel.PayLPCost(tp,1000)
			return
		end
	end
	
	Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
end

function s.redirect_con(e)
	local re = e:GetHandler():GetReasonEffect()
	if not re then return true end 
	local rc = re:GetHandler()
	if rc and rc:IsSetCard(ID_ARCHETYPE) then
		return false 
	end
	return true
end