CMwNod@ Dev_GetOffsetNodSafe(CMwNod@ target, uint16 offset) {
    if (target is null) return null;
    auto ptr = Dev::GetOffsetUint64(target, offset);
    if (ptr < 0x100000000) return null;
    if (ptr % 8 != 0) return null;
    return Dev::GetOffsetNod(target, offset);
}

uint64 Dev_GetPointerForNod(CMwNod@ nod) {
    if (nod is null) throw('nod was null');
    auto tmpNod = CMwNod();
    uint64 tmp = Dev::GetOffsetUint64(tmpNod, 0);
    Dev::SetOffset(tmpNod, 0, nod);
    uint64 ptr = Dev::GetOffsetUint64(tmpNod, 0);
    Dev::SetOffset(tmpNod, 0, tmp);
    return ptr;
}

CMwNod@ Dev_GetNodFromPointer(uint64 ptr) {
    if (ptr < 0xFFFFFFFF || ptr % 8 != 0 || ptr >> 48 > 0) {
        return null;
    }
    auto tmpNod = CMwNod();
    uint64 tmp = Dev::GetOffsetUint64(tmpNod, 0);
    Dev::SetOffset(tmpNod, 0, ptr);
    auto nod = Dev::GetOffsetNod(tmpNod, 0);
    Dev::SetOffset(tmpNod, 0, tmp);
    return nod;
}

uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}
uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
    if (obj is null) return 0xFFFF;
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(obj);
    if (ty is null) throw("could not find a type for object");
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}
