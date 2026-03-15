-- Goddess Nikke Red Hood
-- ID: 99900031
local s,id=GetID()
local ID_RAPI = 99900000		  
local ID_RAPI_RED_HOOD = 99900006 

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ==================================================================
	-- [SMART MANUAL] Link Summon Procedure (Updated)
	-- ==================================================================
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

	-- 1. Battle Protections
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- 2. Battle Logic (Negate Both Ways)
	-- [A] We Attack
	local e3a=Effect.CreateEffect(c)
	e3a:SetDescription(aux.Stringid(id,2))
	e3a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3a:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3a:SetOperation(s.negop)
	c:RegisterEffect(e3a)
	-- [B] We are Attacked
	local e3b=Effect.CreateEffect(c)
	e3b:SetDescription(aux.Stringid(id,2))
	e3b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3b:SetCode(EVENT_BE_BATTLE_TARGET)
	e3b:SetOperation(s.negop)
	c:RegisterEffect(e3b)

	-- 3. Battle Logic (Destroy After Calculation)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_BATTLED)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- 4. Snipe Effect (Destroy Opponent's Card Only + Unchainable)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e5:SetCost(s.sncost)
	e5:SetTarget(s.sntg)
	e5:SetOperation(s.snop)
	c:RegisterEffect(e5)

	-- 5. Floating Effect (Ignore Condition + Unchainable)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_ATKCHANGE)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCondition(s.spcon)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

-- ==================================================================
-- [SMART LOGIC] Summoning Procedure (Updated)
-- ==================================================================
function s.get_link_val(c) return c:IsType(TYPE_LINK) and c:GetLink() or 1 end

function s.link_check(g,lc,tp)
	-- 1. [Specific Check] ต้องมี "Nikke Rapi" (ID_RAPI) อย่างน้อย 1 ใบ
	if not g:IsExists(Card.IsCode,1,nil,ID_RAPI) then return false end
	
	-- 2. ผลรวม Link Rating ต้องได้ 4
	local sum = 0
	for tc in aux.Next(g) do sum = sum + s.get_link_val(tc) end
	if sum ~= 4 then return false end

	-- 3. [Smart Fix] เช็คว่าถ้าใช้วัตถุดิบนี้ (g) แล้วจะมีช่องว่างให้ (lc) ลงไหม
	return Duel.GetLocationCountFromEx(tp,tp,g,lc)>0
end

function s.matfilter(c) 
	return c:IsFaceup() and c:IsCanBeLinkMaterial(nil) 
end

function s.linkcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	-- ใช้ CheckSubGroup เพื่อหาความเป็นไปได้ที่ผ่านเงื่อนไข link_check ทั้ง 3 ข้อ
	return g:CheckSubGroup(s.link_check,2,4,c,tp)
end

function s.linktg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LMATERIAL)
	-- เลือกเฉพาะกลุ่มที่ผ่านการตรวจสอบ
	local sg=g:SelectSubGroup(tp,s.link_check,false,2,4,c,tp)
	if sg then 
		sg:KeepAlive() 
		e:SetLabelObject(sg) 
		return true 
	else 
		return false 
	end
end

function s.linkop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	c:SetMaterial(sg)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_LINK)
	sg:DeleteGroup()
end

-- ==================================================================
-- Battle Logic
-- ==================================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		Duel.Hint(HINT_CARD,0,id)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		bc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		bc:RegisterEffect(e2)
	end
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc or not bc:IsRelateToBattle() then return false end
	return bc:GetAttack() > c:GetAttack() or bc:GetDefense() > c:GetAttack()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if bc and bc:IsRelateToBattle() then Duel.Destroy(bc,REASON_BATTLE) end
end

-- ==================================================================
-- Snipe Functions
-- ==================================================================
function s.sncost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1500) end
	Duel.PayLPCost(tp,1500)
end
function s.sntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
	Duel.SetChainLimit(s.chainlm)
end
function s.chainlm(e,rp,tp) return false end
function s.snop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- ==================================================================
-- Floating Functions
-- ==================================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.rapi_filter(c,e,tp)
	return c:IsCode(ID_RAPI_RED_HOOD) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.rapi_filter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetChainLimit(s.chainlm)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.SelectMatchingCard(tp,s.rapi_filter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE) e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(2000) e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE) e2:SetCode(EFFECT_IMMUNE_EFFECT)
		e2:SetValue(s.efilter) 
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, 2)
		tc:RegisterEffect(e2)
	end
end
function s.efilter(e,re) return e:GetOwnerPlayer()~=re:GetOwnerPlayer() end