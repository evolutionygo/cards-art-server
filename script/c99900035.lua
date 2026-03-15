-- Goddess Nikke Dorothy
-- ID: 99900035
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(COUNTER_SPELL)

	-- Link Summon (Smart Logic)
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

	-- 1. Ultimate Protection
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_RELEASE)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_TO_HAND)
	c:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e3)

	-- 2. Paradise Brand (Counters)
	-- 2.1 On Summon (Mandatory / Auto)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_COUNTER)
	-- ใช้ TRIGGER_F (Forced) เพื่อให้ทำงานอัตโนมัติทันที
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) 
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetOperation(s.addc)
	c:RegisterEffect(e4)

	-- 2.2 Recharge (Continuous)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_CHAIN_SOLVED)
	e5:SetRange(LOCATION_MZONE)
	e5:SetOperation(s.rechargeop)
	c:RegisterEffect(e5)

	-- 3. Resource Support (Search)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,id)
	e6:SetCost(s.thcost)
	e6:SetTarget(s.thtg)
	e6:SetOperation(s.thop)
	c:RegisterEffect(e6)

	-- 4. Over Zone (One-Sided Column Shutdown)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_DISABLE)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_CHAINING)
	e7:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCondition(s.negcon)
	e7:SetCost(s.negcost)
	e7:SetTarget(s.negtg)
	e7:SetOperation(s.negop)
	c:RegisterEffect(e7)
end

-- ==================================================================
-- Link Logic
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
-- Counter Logic
-- ==================================================================
function s.addc(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then c:AddCounter(COUNTER_SPELL,1) end
end
function s.rechargeop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsSetCard(ID_NIKKE) and re:GetHandler():IsType(TYPE_SPELL+TYPE_TRAP) then
		c:AddCounter(COUNTER_SPELL,1)
	end
end

-- ==================================================================
-- Search Logic
-- ==================================================================
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
function s.thfilter(c)
	return c:IsSetCard(ID_NIKKE) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ==================================================================
-- Over Zone (Opponent-Only Column Shutdown)
-- ==================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,COUNTER_SPELL,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,COUNTER_SPELL,1,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- Helper: คำนวณ Mask คอลัมน์ (เหมือนเดิม)
function s.get_disable_mask(c)
	local mask = 0
	local my_seq = c:GetSequence()
	if my_seq < 5 then mask = mask | (1 << my_seq) end
	if my_seq == 5 then mask = mask | (1 << 1) end 
	if my_seq == 6 then mask = mask | (1 << 3) end 

	local linked = c:GetLinkedZone() 
	for i=0,4 do
		if (linked & (1<<i)) ~= 0 then mask = mask | (1<<i) end
	end
	for i=0,4 do
		if (linked & (1<<(16+i))) ~= 0 then
			local opp_col = 4-i 
			mask = mask | (1<<opp_col)
		end
	end
	return mask
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
		
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local disable_mask = s.get_disable_mask(c)
			
			-- สร้าง Effect ปิดตาย
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_DISABLE)
			-- แก้ไข: Target Range เป็น (0, LOCATION_ONFIELD) = ฝั่งตรงข้ามเท่านั้น
			e1:SetTargetRange(0, LOCATION_ONFIELD)
			e1:SetTarget(s.distg)
			e1:SetLabel(disable_mask)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
			
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			Duel.RegisterEffect(e2,tp)
			
			Duel.Hint(HINT_ZONE, tp, c:GetLinkedZone())
		end
	end
end

-- เป้าหมาย: เช็คว่าเป็นคอลัมน์ที่ถูก Mask ไว้หรือไม่ (ใช้กับ SetTargetRange 0,...)
function s.distg(e,c)
	local mask = e:GetLabel()
	local seq = c:GetSequence()
	local col_idx = 0
	
	-- เนื่องจาก TargetRange เราเซ็ตเป็น Opponent Only
	-- c จะเป็นฝ่ายตรงข้ามเสมอ (c:IsControler(1-tp))
	-- ดังนั้นเข้า Logic แปลงตำแหน่งฝ่ายตรงข้ามเลย
	if c:IsLocation(LOCATION_MZONE) then
		if seq==5 then col_idx=3 elseif seq==6 then col_idx=1 else col_idx=4-seq end
	elseif c:IsLocation(LOCATION_SZONE) then
		col_idx=4-seq
	end
	
	-- เช็ค Mask
	return (mask & (1<<col_idx)) ~= 0
end