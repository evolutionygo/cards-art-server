-- Goddess Nikke Snow White
-- ID: 99900032
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Link Summon
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.linkcon)
	e0:SetTarget(s.linktg)
	e0:SetOperation(s.linkop)
	e0:SetValue(SUMMON_TYPE_LINK)
	c:RegisterEffect(e0)

	-- 1. Protection (Prevent Destroy/Banish/Send by Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_DESTROY_REPLACE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTarget(s.reptg)
	e1:SetValue(s.repval)
	e1:SetOperation(s.repop)
	c:RegisterEffect(e1)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SEND_REPLACE)
	e2:SetTarget(s.reptg_send)
	e2:SetValue(s.repval_send)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	-- 2. Scavenging (Gain ATK)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetTarget(s.scavtg)
	e3:SetOperation(s.scavop)
	c:RegisterEffect(e3)

	-- 3. Seven Dwarves (Updated Logic)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(2)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCost(s.firecost)
	e4:SetTarget(s.firetg)
	e4:SetOperation(s.fireop)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- Link Summon Logic
-- ==================================================================
function s.get_link_val(c) return c:IsType(TYPE_LINK) and c:GetLink() or 1 end
function s.link_check(g,lc,tp)
	if not g:IsExists(Card.IsSetCard,1,nil,ID_NIKKE) then return false end
	local sum = 0
	for tc in aux.Next(g) do sum = sum + s.get_link_val(tc) end
	if sum ~= 4 then return false end
	return Duel.GetLocationCountFromEx(tp,tp,g,lc)>0
end
function s.matfilter(c) return c:IsFaceup() and c:IsCanBeLinkMaterial(nil) end
function s.linkcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	return g:CheckSubGroup(s.link_check,2,4,c,tp)
end
function s.linktg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LMATERIAL)
	local sg=g:SelectSubGroup(tp,s.link_check,false,2,4,c,tp)
	if sg then sg:KeepAlive() e:SetLabelObject(sg) return true else return false end
end
function s.linkop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	c:SetMaterial(sg)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_LINK)
	sg:DeleteGroup()
end

-- ==================================================================
-- Protection Logic
-- ==================================================================
function s.repfilter(c) 
	return c:IsRace(RACE_MACHINE) and c:IsAbleToRemove() and ((c:IsOnField() and c:IsFaceup()) or c:IsLocation(LOCATION_GRAVE)) 
end

function s.source_check(e)
	local c=e:GetHandler()
	local reason_eff=c:GetReasonEffect()
	if not reason_eff then return false end
	local sc=reason_eff:GetHandler()
	if not sc then return false end
	
	local is_machine = sc:IsRace(RACE_MACHINE)
	local is_atk_pos = sc:IsType(TYPE_MONSTER) and sc:IsPosition(POS_ATTACK)
	return is_machine or is_atk_pos
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsReason(REASON_EFFECT) 
		and not c:IsReason(REASON_REPLACE) 
		and s.source_check(e) 
		and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,c) 
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,c)
		e:SetLabelObject(g:GetFirst())
		return true
	else return false end
end

function s.reptg_send(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsReason(REASON_EFFECT) 
		and not c:IsReason(REASON_REPLACE) 
		and (c:GetDestination()==LOCATION_GRAVE or c:GetDestination()==LOCATION_REMOVED)
		and s.source_check(e) 
		and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,c) 
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,c)
		e:SetLabelObject(g:GetFirst())
		return true
	else return false end
end

function s.repval(e,c) return s.reptg(e,c:GetControler(),nil,nil,nil,nil,nil,nil,0) end
function s.repval_send(e,c) return s.reptg_send(e,c:GetControler(),nil,nil,nil,nil,nil,nil,0) end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end

-- ==================================================================
-- Scavenging Logic
-- ==================================================================
function s.scavtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,LOCATION_GRAVE)
end
function s.scavop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,3,nil)
	if #g>0 then
		local count=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		if count>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(count*400)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
		end
	end
end

-- ==================================================================
-- Seven Dwarves Logic (Final Optimized Version)
-- ==================================================================
function s.firecost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetAttack() >= 1000 end
	
	-- ลด ATK 1000 (เป็น Cost)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(-1000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
	
	-- ห้ามโจมตีในเทิร์นนี้ (สำคัญมาก เพื่อแก้ปัญหา Replay/Lag)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_ATTACK)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_OATH)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e2)
end

function s.tgtfilter(c, limit_atk)
	-- เป้าหมายต้องมี ATK ต่ำกว่าค่า limit_atk
	return c:IsFaceup() and c:IsAbleToRemove() and c:GetAttack() < limit_atk
end

function s.firetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.tgtfilter(chkc,c:GetAttack()) end
	
	if chk==0 then
		-- Predictive Check: ตรวจสอบว่าถ้าหักลบ 1000 แล้ว ยังมีเป้าหมายให้ยิงไหม?
		-- ใช้ c:GetAttack() - 1000 เพื่อดูอนาคต
		return Duel.IsExistingTarget(s.tgtfilter,tp,0,LOCATION_MZONE,1,nil,c:GetAttack()-1000)
	end
	
	-- ถึงจุดนี้ Cost ถูกจ่ายไปแล้ว (ATK ลดแล้ว) ดังนั้นใช้ c:GetAttack() ปัจจุบันได้เลย
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.tgtfilter,tp,0,LOCATION_MZONE,1,1,nil,c:GetAttack())
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

function s.fireop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	if tc and tc:IsRelateToEffect(e) then
		local target_atk = tc:GetAttack()
		if target_atk < 0 then target_atk = 0 end
		
		-- รีมูฟ
		if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT) ~= 0 then
			-- ถ้า Snow White ยังอยู่ ให้คำนวณดาเมจ
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local my_atk = c:GetAttack()
				-- ความต่างของ ATK (พลังเรา - พลังศัตรู)
				if my_atk > target_atk then
					Duel.Damage(1-tp, my_atk - target_atk, REASON_EFFECT)
				end
			end
		end
	end
end