-- Goddess Nikke Scarlet
-- ID: 99900033
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	-- ==================================================================
	-- [SMART MANUAL] Link Summon Procedure
	-- ==================================================================
	c:EnableReviveLimit()
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

	-- 1. ไม่ถูกทำลายจากการต่อสู้
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. ระบบภูมิคุ้มกัน (ยกเว้นธีม Nikke)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.nikke_immune_filter)
	c:RegisterEffect(e2)

	-- 3. ระบบเพิ่มพลัง: [ห้ามเชนต่อ]
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_BATTLED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.atk_boost_con)
	e3:SetTarget(s.atk_boost_tg)
	e3:SetOperation(s.atk_boost_op)
	c:RegisterEffect(e3)

	-- 4. [ATK 2000+] Attack All
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_ATTACK_ALL) 
	e4:SetRange(LOCATION_MZONE)   
	e4:SetCondition(s.atk2000con)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	-- 5. [ATK 4000+] Piercing
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_PIERCE)
	e5:SetRange(LOCATION_MZONE)   
	e5:SetCondition(s.atk4000con)
	c:RegisterEffect(e5)

	-- 6. [ATK 5000+] Double Piercing
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.atk5000con)
	e6:SetOperation(s.doublepierceop)
	c:RegisterEffect(e6)
end

-- ==========================================
-- Logic: Nikke-Friendly Immunity Filter [FIXED]
-- ==========================================
function s.nikke_immune_filter(e,te)
	-- 1. ถ้าคนใช้เป็น Nikke ให้ผ่านตลอด (ไม่กัน)
	if te:GetOwner():IsSetCard(ID_NIKKE) then return false end

	-- 2. กรณีเป็น Activated Effect (เอฟเฟกต์ที่ต้องกดใช้/เข้าเชน)
	-- ให้เช็คที่ "Category" ว่ามีการระบุเรื่อง ลดพลัง หรือ เนเกจ หรือไม่
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		local is_stat_cat = (cat & CATEGORY_ATKCHANGE)~=0 or (cat & CATEGORY_DEFCHANGE)~=0
		local is_negate_cat = (cat & CATEGORY_DISABLE)~=0
		return is_stat_cat or is_negate_cat
	end

	-- 3. กรณีเป็น Continuous Effect (เอฟเฟกต์ต่อเนื่อง/สนาม/สวมใส่)
	-- ให้เช็คที่ "Code" โดยตรงเหมือนเดิม
	local ec = te:GetCode()
	local is_stat_code = ec==EFFECT_UPDATE_ATTACK or ec==EFFECT_UPDATE_DEFENSE
		or ec==EFFECT_SET_ATTACK or ec==EFFECT_SET_DEFENSE
		or ec==EFFECT_SET_ATTACK_FINAL or ec==EFFECT_SET_DEFENSE_FINAL
		or ec==EFFECT_SET_BASE_ATTACK or ec==EFFECT_SET_BASE_DEFENSE
		or ec==EFFECT_SWAP_ATTACK_FINAL or ec==EFFECT_SWAP_DEFENSE_FINAL
		or ec==EFFECT_SWAP_AD
	local is_negate_code = ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
	
	return is_stat_code or is_negate_code
end

-- ==========================================
-- Logic: ATK Overpower
-- ==========================================
function s.atk_boost_con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc or not bc:IsRelateToBattle() then return false end
	local target_val = math.max(bc:GetAttack(), bc:GetDefense())
	return target_val > c:GetAttack()
end

function s.atk_boost_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetChainLimit(aux.FALSE)
end

function s.atk_boost_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not c:IsRelateToEffect(e) or c:IsFacedown() or not bc then return end
	local boost_val = math.max(bc:GetAttack(), bc:GetDefense())
	if boost_val > 0 then
		Duel.Hint(HINT_CARD,0,id)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(boost_val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end

-- ==========================================
-- Logic: Threshold Conditions
-- ==========================================
function s.atk2000con(e) return e:GetHandler():GetAttack() >= 2000 end
function s.atk4000con(e) return e:GetHandler():GetAttack() >= 4000 end

function s.atk5000con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return ep~=tp and c:IsRelateToBattle() and bc and bc:IsDefensePos() and c:GetAttack() >= 5000
end

function s.doublepierceop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(ep,ev*2)
end

-- ==================================================================
-- Logic: Link Summon
-- ==================================================================
function s.get_link_val(c) return c:IsType(TYPE_LINK) and c:GetLink() or 1 end

function s.link_check(g,lc,tp)
	if not g:IsExists(Card.IsSetCard,1,nil,ID_NIKKE) then return false end
	local sum = 0
	for tc in aux.Next(g) do sum = sum + s.get_link_val(tc) end
	if sum ~= 4 then return false end
	return Duel.GetLocationCountFromEx(tp,tp,g,lc)>0
end

function s.matfilter(c) 
	return c:IsFaceup() and c:IsCanBeLinkMaterial(nil) 
end

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