-- Brave Blade - Stellar Drift
-- ID: 188800012
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

	-- [TRAP EFFECT: Main Phase Reset & Summon (Unchainable)]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_DECK)
	e2:SetHintTiming(0,TIMING_MAIN_END)
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
-- [Trap Effect Logic - Main Phase Reset & Summon]
-- ==================================================================
function s.trap_con(e,tp,eg,ep,ev,re,r,rp)
	local ph = Duel.GetCurrentPhase()
	return (ph == PHASE_MAIN1 or ph == PHASE_MAIN2) and Duel.GetFieldGroupCount(tp, LOCATION_ONFIELD, 0) > 0
end

function s.trap_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.has_free_pzone(tp) end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_ONFIELD)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, nil, 1, 0, 0)
	
	Duel.SetChainLimit(aux.FALSE)
	
	s.setup_banish_hook(e,tp)
end

function s.thfilter(c)
	return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.trap_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	
	-- 1. วางลง P-Zone
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	-- 2. เคลียร์สนาม
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck, tp, LOCATION_ONFIELD, 0, c)
	if #g>0 then
		Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	end
	
	-- 3. หาของขึ้นมือ
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local sg=Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, 1, nil)
	
	if #sg>0 then
		local tc=sg:GetFirst()
		if Duel.SendtoHand(tc,nil,REASON_EFFECT) > 0 then
			Duel.ConfirmCards(1-tp, tc)
			
			if tc:IsLocation(LOCATION_HAND) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DECREASE_TRIBUTE)
				e1:SetValue(0x30003) 
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				
				if tc:IsSummonable(true, nil) then
					Duel.BreakEffect()
					-- แยกคำสั่ง Summon ออกจากบรรทัด if เพื่อไม่ให้บั๊ก
					Duel.Summon(tp, tc, true, nil) 
					
					-- เช็คสถานะการ์ดหลังจาก Summon สำเร็จ
					if tc:IsCode(ID_PISCES_MIST) and tc:IsLocation(LOCATION_MZONE) then
						-- โล่ป้องกันเอฟเฟค
						local e2=Effect.CreateEffect(c)
						e2:SetType(EFFECT_TYPE_FIELD)
						e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
						e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
						e2:SetTargetRange(LOCATION_MZONE, 0)
						e2:SetTarget(function(eff,mc) return mc:IsFaceup() and mc:IsSetCard(ID_ARCHETYPE) end)
						e2:SetValue(aux.tgoval)
						e2:SetReset(RESET_PHASE+PHASE_END, 2)
						Duel.RegisterEffect(e2, tp)
						
						-- โล่ป้องกันเป้าหมายการโจมตี
						local e3=Effect.CreateEffect(c)
						e3:SetType(EFFECT_TYPE_FIELD)
						e3:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
						e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
						e3:SetTargetRange(LOCATION_MZONE, 0)
						e3:SetTarget(function(eff,mc) return mc:IsFaceup() and mc:IsSetCard(ID_ARCHETYPE) end)
						e3:SetValue(aux.imval1)
						e3:SetReset(RESET_PHASE+PHASE_END, 2)
						Duel.RegisterEffect(e3, tp)
						
						tc:RegisterFlagEffect(0, RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, EFFECT_FLAG_CLIENT_HINT, 2, 0, aux.Stringid(id, 2))
					end
				end
			end
		end
	end
end