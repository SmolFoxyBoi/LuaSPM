import Foundation
import lua

infix operator ~> // get to var
infix operator <~ // set

internal class LuaVarPointer {
    internal var lua_instance: LuaSPM?
    internal var path: String
    convenience internal init() {
        self.init(nil, "nil")
    }
    internal init(_ lua_instance: LuaSPM?, _ path: String) {
        self.lua_instance = lua_instance
        self.path = path
    }
    internal func access(_ fn: () throws -> Any) throws -> Any { // exposes the variable and places it in the lua stack at -1, passed function does what you need to do to the var, the var is then poped off the stack
        if lua_instance != nil {
            if !path.contains(".") {
                luaS_getglobal(lua_instance?.VM, path)
                let out = try fn()
                luaS_pop(lua_instance?.VM, 1)
                return out
            }
            else {
                throw LuaSPMError.notImplemented
            }
        }
        else {
            throw LuaSPMError.noLuaInstance
        }
    }
}

public class LuaSPMSharedVar { // base of any shared var
    internal var lua_instance: LuaSPM?
    internal var represents: LuaVarPointer
    convenience internal init(_ lua_instance: LuaSPM?) {
        self.init(LuaVarPointer(lua_instance, "nil"), lua_instance)
    }
    internal init(_ represents: LuaVarPointer, _ lua_instance: LuaSPM?) {
        self.represents = represents
        self.lua_instance = lua_instance
    }
}

public struct LuaSPMShared {
    public class LuaBool: LuaSPMSharedVar {
        internal init(_ path: String, _ lua_instance: LuaSPM?) {
            super.init(LuaVarPointer(lua_instance, path), lua_instance)
        }
        public func getValue() -> Bool {
            var out: Bool = false
            self~>out
            return out
        }
        public static func ~>(_ slf: LuaBool, _ out: inout Bool) {
            func getter() throws -> Bool {
                if luaS_isboolean(slf.lua_instance?.VM, -1) != 0 {
                    let out = luaS_toboolean(slf.lua_instance?.VM, -1)
                    if out == 0 {
                        return false
                    }
                    else {
                        return true
                    }
                }
                else {
                    throw LuaSPMError.variableNotFound
                }
            }
            do {
                out =  try slf.represents.access(getter) as! Bool
                return
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
        public static func <~(_ slf: LuaBool, _ var_in: Bool) {
            func setter() throws {
                if luaS_isboolean(slf.lua_instance?.VM, -1) != 0 {
                    var to_set: Int32 = -1
                    switch var_in {
                        case true:
                            to_set = 1
                            break
                        case false:
                            to_set = 0
                            break
                    }
                    luaS_pushboolean(slf.lua_instance?.VM, to_set)
                    luaS_setglobal(slf.lua_instance?.VM, slf.represents.path)
                }
            }
            do {
                let _ = try slf.represents.access(setter)
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
    }
    public class LuaNumber: LuaSPMSharedVar {
        internal init(_ path: String, _ lua_instance: LuaSPM?) {
            super.init(LuaVarPointer(lua_instance, path), lua_instance)
        }
        public func getValue() -> Double {
            var out: Double = 0
            self~>out
            return out
        }
        public static func ~>(_ slf: LuaNumber, _ out: inout Double) {
            func getter() throws -> Double {
                if luaS_isnumber(slf.lua_instance?.VM, -1) != 0 {
                    return luaS_tonumber(slf.lua_instance?.VM, -1)
                }
                else {
                    throw LuaSPMError.variableNotFound
                }
            }
            do {
                out =  try slf.represents.access(getter) as! Double
                return
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
        public static func <~(_ slf: LuaNumber, _ var_in: Double) {
            func setter() throws {
                if luaS_isnumber(slf.lua_instance?.VM, -1) != 0 {
                    luaS_pushnumber(slf.lua_instance?.VM, var_in)
                    luaS_setglobal(slf.lua_instance?.VM, slf.represents.path)
                }
            }
            do {
                let _ = try slf.represents.access(setter)
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
    }
    public class LuaString: LuaSPMSharedVar {
        internal init(_ path: String, _ lua_instance: LuaSPM?) {
            super.init(LuaVarPointer(lua_instance, path), lua_instance)
        }
        public func getValue() -> String {
            var out: String = ""
            self~>out
            return out
        }
        public static func ~>(_ slf: LuaString, _ out: inout String) {
            func getter() throws -> String {
                if luaS_isstring(slf.lua_instance?.VM, -1) != 0 {
                    return String(cString: luaS_tostring(slf.lua_instance?.VM, -1))
                }
                else {
                    throw LuaSPMError.variableNotFound
                }
            }
            do {
                out =  try slf.represents.access(getter) as! String
                return
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
        public static func <~(_ slf: LuaString, _ var_in: String) {
            func setter() throws {
                if luaS_isstring(slf.lua_instance?.VM, -1) != 0 {
                    luaS_pushstring(slf.lua_instance?.VM, var_in)
                    luaS_setglobal(slf.lua_instance?.VM, slf.represents.path)
                }
            }
            do {
                let _ = try slf.represents.access(setter)
            }
            catch {
                print("\(error)")
                exit(-1)
            }
        }
    }
}
