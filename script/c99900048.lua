-- Burst: Burning Scourge
-- ID: 99900048
local s,id=GetID()
local ID_NIHILISTER = 99900043 -- ID ของ Heretic Nikke Nihilister

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetHintTiming(TIMING_ATTACK,TIMING_ATTACK+TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==================================================================
-- Logic 1: Activation Condition
-- ==================================================================
function s.filter_nihilister(c)
	return c:IsFaceup() and c:IsCode(ID_NIHILISTER)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.filter_nihilister,tp,LOCATION_MZONE,0,1,nil) then return false end
	
	-- Check Chain (Opponent Monster Effect)
	local chain = Duel.GetCurrentChain()
	if chain > 0 then
		local te, p = Duel.GetChainInfo(chain, CHAININFO_TRIGGERING_EFFECT, CHAININFO_TRIGGERING_PLAYER)
		if te and te:IsActiveType(TYPE_MONSTER) and p == 1-tp then
			return true
		end
	end

	-- Check Attack
	if Duel.CheckEvent(EVENT_ATTACK_ANNOUNCE) then
		local at = Duel.GetAttacker()
		if at and at:IsControler(1-tp) then
			return true
		end
	end
	
	return false
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	
	-- Identify Target for Info (Non-Targeting)
	local rc = nil
	if Duel.CheckEvent(EVENT_ATTACK_ANNOUNCE) then
		rc = Duel.GetAttacker()
	else
		local chain = Duel.GetCurrentChain()
		if chain > 0 then
			local te = Duel.GetChainInfo(chain, CHAININFO_TRIGGERING_EFFECT)
			if te then rc = te:GetHandler() end
		end
	end

	if rc then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
	end
	
	local count=Duel.GetMatchingGroupCount(Card.IsFacedown,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,count*200)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- ====================================================
	-- PART 1: Damage & Destroy
	-- ====================================================
	local tc = nil
	local is_battle = false
	
	if Duel.CheckEvent(EVENT_ATTACK_ANNOUNCE) then
		tc = Duel.GetAttacker()
		is_battle = true
	else
		local chain = Duel.GetCurrentChain()-1
		if chain > 0 then
			local te = Duel.GetChainInfo(chain, CHAININFO_TRIGGERING_EFFECT)
			if te then tc = te:GetHandler() end
		end
	end

	local count=Duel.GetMatchingGroupCount(Card.IsFacedown,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	local dmg = count * 200
	
	if dmg > 0 then
		if Duel.Damage(1-tp, dmg, REASON_EFFECT) > 0 then
			if tc then
				local can_destroy = false
				if is_battle then
					if tc:IsRelateToBattle() then can_destroy = true end
				else
					local chain = Duel.GetCurrentChain()-1
					if chain > 0 then
						local te = Duel.GetChainInfo(chain, CHAININFO_TRIGGERING_EFFECT)
						if tc:IsRelateToEffect(te) then can_destroy = true end
					end
				end
				
				if can_destroy then
					Duel.Destroy(tc, REASON_EFFECT)
				end
			end
		end
	end
	
	-- ====================================================
	-- PART 2: Lingering Effects (Nerfed to Next Turn)
	-- ====================================================
	
	-- Effect A: Change Monster Effects (Using Continuous Monitor)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAIN_SOLVING)
	e1:SetOperation(s.replace_op) 
	e1:SetReset(RESET_PHASE+PHASE_END, 2) -- [แก้ไข] เปลี่ยนจาก 3 เป็น 2
	Duel.RegisterEffect(e1,tp)
	
	-- Effect B: Attack Burn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetOperation(s.atk_burn_op)
	e2:SetReset(RESET_PHASE+PHASE_END, 2) -- [แก้ไข] เปลี่ยนจาก 3 เป็น 2
	Duel.RegisterEffect(e2,tp)
	
	-- เพิ่ม Hint (icon สีเขียว) เพื่อให้ผู้เล่นรู้ว่าเอฟเฟคยังค้างอยู่
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e3:SetDescription(aux.Stringid(id,1)) -- "Debuff Active"
	e3:SetTargetRange(1,0)
	e3:SetReset(RESET_PHASE+PHASE_END, 2) -- [แก้ไข] เปลี่ยนจาก 3 เป็น 2
	Duel.RegisterEffect(e3,tp)
end

-- ==================================================================
-- Logic 3: Lingering Functions
-- ==================================================================

function s.replace_op(e,tp,eg,ep,ev,re,r,rp)
	if rp==1-tp and re:IsActiveType(TYPE_MONSTER) then
		Duel.ChangeChainOperation(ev,s.burn_op)
	end
end

function s.burn_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(tp,500,REASON_EFFECT)
	Duel.Damage(1-tp,500,REASON_EFFECT)
end

function s.atk_burn_op(e,tp,eg,ep,ev,re,r,rp)
	local at=Duel.GetAttacker()
	if at and at:IsControler(1-tp) then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Damage(1-tp,500,REASON_EFFECT)
	end
end