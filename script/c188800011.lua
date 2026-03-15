-- Brave Blade - Star Shaper
-- ID: 188800011
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  
local ID_PISCES_MIST = 188800009

function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e0)

	-- [HAND EFFECT / PENDULUM]
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

	-- [TRAP EFFECT: Multi-Banish & Attack Lock]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_DECK)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.trap_con)
	e2:SetTarget(s.trap_tg)
	e2:SetOperation(s.trap_op)
	c:RegisterEffect(e2)
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

function s.setup_banish_hook(e,tp)
	local c=e:GetHandler()
	local e_banish=Effect.CreateEffect(c)
	e_banish:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e_banish:SetCode(EVENT_CHAIN_END)
	e_banish:SetLabelObject(c)
	e_banish:SetOperation(s.banish_end_op)
	e_banish:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e_banish,tp)
end

function s.banish_end_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c then Duel.Remove(c,POS_FACEUP,REASON_EFFECT) end
	e:Reset() 
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
			return Duel.IsExistingMatchingCard(function(c) return not c:IsSetCard(ID_ARCHETYPE) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,nil)
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
		local thg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) and tc:IsAbleToHand() end),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
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
		local deck=Duel.GetMatchingGroup(function(tc) return not tc:IsSetCard(ID_ARCHETYPE) and tc:IsAbleToHand() end,tp,LOCATION_DECK,0,nil)
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
-- [Trap Effect Logic]
-- ==================================================================
function s.trap_con(e,tp,eg,ep,ev,re,r,rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	-- เมื่ออีกฝ่ายสั่งใช้เอฟเฟคบนสนาม
	return rp == 1-tp and (loc & LOCATION_ONFIELD ~= 0) and s.controls_only_bb(tp)
end

function s.trap_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.has_free_pzone(tp) end
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, 1-tp, LOCATION_ONFIELD)
	s.setup_banish_hook(e,tp)
end

function s.trap_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	
	-- 1. วางลง P-Zone
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	-- 2. ประเมินว่าสามารถทิ้งการ์ดสูงสุดได้กี่ใบ (เช็คว่ามีศัตรูให้แบนิชไหม และมี Pisces Mist หรือเปล่า)
	local has_pisces = Duel.IsExistingMatchingCard(function(mc) return mc:IsFaceup() and mc:IsCode(ID_PISCES_MIST) end, tp, LOCATION_MZONE, 0, 1, nil)
	local max_discard = has_pisces and 3 or 2
	local opp_cards = Duel.GetFieldGroupCount(tp, 0, LOCATION_ONFIELD)
	
	-- ไม่สามารถทิ้งการ์ดเกินจำนวนการ์ดของศัตรูบนสนามได้
	local valid_max = math.min(max_discard, opp_cards)
	
	if valid_max > 0 and Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) > 0 then
		-- 3. เด้งหน้าต่างให้เลือกการ์ดทิ้งทันที (ข้ามการถาม Yes/No ไปเลย)
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
		local discarded = Duel.DiscardHand(tp, Card.IsDiscardable, 1, valid_max, REASON_EFFECT+REASON_DISCARD)
		
		if discarded > 0 then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
			-- 4. บังคับเลือกการ์ดของอีกฝ่ายเพื่อแบนิชแบบคว่ำหน้า ตามจำนวนที่ทิ้งไป
			local bg = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD, discarded, discarded, nil, tp, POS_FACEDOWN)
			if #bg > 0 then
				Duel.Remove(bg, POS_FACEDOWN, REASON_EFFECT)
			end
		end
	end
	
	-- 5. บังคับติดคำสาปห้ามโจมตีให้ Brave Blade ทุกตัวที่ไม่ใช่ Pisces Mist เป็นเวลา 2 เทิร์น
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(function(eff,tc) 
		return tc:IsSetCard(ID_ARCHETYPE) and not tc:IsCode(ID_PISCES_MIST) 
	end)
	e1:SetReset(RESET_PHASE+PHASE_END, 2)
	Duel.RegisterEffect(e1, tp)
end