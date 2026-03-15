-- Nikke FULL BURST!
-- ID: 99900036
local s,id=GetID()
local BURST_SET_ID = 0xc03 

-- ============================================================================
-- CONFIGURATION: BURST SKILL MAPPING
-- ============================================================================
s.skill_map = {
	[99900006] = 99900007, -- Rapi -> Burst: Power of Inheritance
	[99900014] = 99900015, -- Vesti -> Burst: Missile Container Online
	[99900019] = 99900020, -- Laplace -> Burst: Laplace Buster
	[99900023] = 99900027, -- Sugar -> Burst: Trouble Shooter
	[99900039] = 99900040, -- Nayuta -> Burst: Asceticism
}

function s.initial_effect(c)
	-- Activate (Quick-Play)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsFaceup() and s.skill_map[c:GetCode()]
end

function s.rmfilter(c)
	return c:IsSetCard(BURST_SET_ID) and c:IsAbleToRemoveAsCost()
end

-- ============================================================================
-- COST
-- ============================================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g_mons = Duel.GetMatchingGroup(s.filter,tp,LOCATION_MZONE,0,nil)
	
	if chk==0 then return #g_mons>0 and Duel.CheckLPCost(tp,1000) end
	
	-- 1. คำนวณ LP
	local count_limit = math.min(#g_mons, 3)
	local lp_limit = math.floor(Duel.GetLP(tp)/1000)
	local max_ct = math.min(count_limit, lp_limit)

	local t={}
	for i=1,max_ct do table.insert(t,i) end
	
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,0)) 
	local count = Duel.AnnounceNumber(tp, table.unpack(t))
	
	-- 2. จ่าย LP
	Duel.PayLPCost(tp, count*1000)
	e:SetLabel(count)
	
	-- 3. รีมูฟ Burst Skill
	local g_burst = Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_ONFIELD,0,nil)
	if #g_burst > 0 then
		Duel.Remove(g_burst,POS_FACEDOWN,REASON_COST)
	end
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- แจ้งว่าเราจะเคลียร์โซน S/T ของเรา
	local g_st = Duel.GetMatchingGroup(s.st_filter,tp,LOCATION_SZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g_st,#g_st,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,e:GetLabel(),0,0)
end

-- Filter: หาการ์ดในโซนเวทย์กับดัก (Main S/T Zone) ไม่รวม Field Spell
function s.st_filter(c)
	return c:GetSequence() < 5
end

-- ============================================================================
-- OPERATION
-- ============================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local count = e:GetLabel()
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_MZONE,0,nil)
	
	if #g < count then count = #g end
	if count <= 0 then return end
	
	-- 1. เลือก Nikke ตามจำนวนที่จ่าย
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local sg=g:Select(tp,count,count,nil)
	
	-- 2. เคลียร์โซนเวทย์/กับดัก (Main S/T Zone) เข้าเด็ค
	local g_st = Duel.GetMatchingGroup(s.st_filter,tp,LOCATION_SZONE,0,nil)
	if #g_st > 0 then
		Duel.SendtoDeck(g_st,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		Duel.BreakEffect() -- คั่นจังหวะ
	end

	-- 3. สร้าง Token และ Set ลงสนาม
	for tc in aux.Next(sg) do
		local skill_id = s.skill_map[tc:GetCode()]
		if skill_id then
			local token = Duel.CreateToken(tp, skill_id)
			
			-- Set ลงสนาม
			if Duel.SSet(tp, token) > 0 then
				-- [LOGIC] ทำให้เปิดได้เลยในเทิร์นนี้ (ทั้ง Quick-Play และ Trap)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN) -- สำหรับ Quick-Play Spell
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				token:RegisterEffect(e1)
				
				local e2=e1:Clone()
				e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN) -- สำหรับ Trap
				token:RegisterEffect(e2)
			end
		end
	end
	
	-- [PENALTY FIX] คงไว้ตามเดิม (Burst Skill ลงสุสาน -> รีมูฟคว่ำ)
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetOperation(s.banish_op)
	Duel.RegisterEffect(e3,tp)
end

function s.banish_op(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.rmfilter_gy,nil,tp)
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
	end
end

function s.rmfilter_gy(c,tp)
	return c:IsSetCard(BURST_SET_ID) and c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE)
end