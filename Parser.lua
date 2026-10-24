function computeValue4(a, b)
    local function readHandler(d, e, f)
        e = e or 1
        f = f == nil and true or f
        local offset
        if d.Length < d.Offset + e then
            if not d.AllowOverflows then
                offset = d.Offset
                e = d.Length - offset
            end
        end
        local sub, g, h
        if e <= 0 then
            return ""
        else
            g = d.Offset + 1
            h = d.Offset + e
            sub = string.sub(d.Source, g, h)
            if f then
                d:seek(e)
            end
            return sub
        end
    end
    local function seekHandler(d, e)
        local length = d.Length
        d.Offset = math.clamp(d.Offset + e, 0, length)
    end
    local function readNumberHandler(d, e, f)
        local g = e or "I1"
        e = g
        g = string.packsize(g)
        local read
        if d.Length < d.Offset + g then
            return 0
        else
            read = d:read(g, f)
            if #read < g then
                return 0
            else
                return string.unpack(e, read)
            end
        end
    end
    local function appendHandler(d, e)
        d.Source = d.Source .. e
        d.Length = #d.Source
    end
    local function toEndHandler(d)
        d.Offset = d.Length
    end
    local c = {Offset = 0, Source = a}
    c.Length = string.len(a)
    c.AllowOverflows = b == nil and true or b
    c.read = readHandler
    c.seek = seekHandler
    c.readNumber = readNumberHandler
    c.append = appendHandler
    c.toEnd = toEndHandler
    return c
end
function transformValue5(a)
    return a % 2 == 0 and a / 2 or -(a + 1) / 2
end
function transformValue6(rrotate)
    rrotate = bit32.rrotate(rrotate, 1)
    return string.unpack(">f", string.pack(">I4", rrotate))
end
function StringHandler(a)
    return a:read(a:readNumber("<I4"))
end
function Int32Handler(a)
    return ap(a:readNumber(">I4"))
end
function Int64Handler(a)
    return ap(a:readNumber(">I8"))
end
function Float32Handler(a)
    return aq(a:readNumber(">I4"))
end
function Float64Handler(a)
    return a:readNumber("<d")
end
function InterleaveArrayWithSizeHandler(a, b, c)
    local read2, create, d, e, create2, f, g, h
    if b < 0 then
        return ar("", false)
    else
        read2 = a:read(b * c)
        create = table.create(b)
        d = 1
        e = b
        if 1 <= e then
            while true do
                create2 = table.create(c)
                f = 0
                g = c - 1
                if 0 <= g then
                    while true do
                        h = d + b * f
                        create2[f + 1] = string.sub(read2, h, h)
                        f = f + 1
                        if f + 1 > g then
                            break
                        end
                    end
                end
                create[d] = table.concat(create2)
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return ar(table.concat(create), false)
    end
end
function Int32ArrayHandler(a, b)
    local create3, interleaveArrayWithSize, c, d
    if b < 1 then
        return {}
    else
        create3 = table.create(b)
        interleaveArrayWithSize = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create3[c] = as.Int32(interleaveArrayWithSize)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create3
    end
end
function RbxF32ArrayHandler(a, b)
    local create4, interleaveArrayWithSize2, c, d
    if b < 1 then
        return {}
    else
        create4 = table.create(b)
        interleaveArrayWithSize2 = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create4[c] = as.Float32(interleaveArrayWithSize2)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create4
    end
end
function RefArrayHandler(a, b)
    local create5, int32Array, c, d, e, f
    if b < 1 then
        return {}
    else
        create5 = table.create(b)
        int32Array = as.Int32Array(a, b)
        c = 0
        d = 1
        e = b
        if 1 <= e then
            while true do
                f = c + int32Array[d]
                create5[d] = f
                c = f
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return create5
    end
end
function runProtected5(data, isError)
    local decompress = ab and ab.lz4decompress
    if type(decompress) ~= "function" then
        if isError then error("LZ4 decompression is unavailable", 2) end
        return nil, "LZ4 decompression is unavailable"
    end
    local ok, result = pcall(decompress, data)
    if ok and type(result) == "string" then return result end
    if isError then error(tostring(result or "LZ4 decompression failed"), 2) end
    return nil, tostring(result or "LZ4 decompression failed")
end
function runProtected6(data)
    local decompress = ab and ab.zstddecompress
    if type(decompress) ~= "function" then return nil, "ZSTD decompression is unavailable" end
    local ok, result = pcall(decompress, data)
    if ok and type(result) == "string" then return result end
    return nil, tostring(result or "ZSTD decompression failed")
end
function runProtected7(data)
    local compress = ab and ab.lz4compress
    if type(compress) ~= "function" then return nil, "LZ4 compression is unavailable" end
    local ok, result = pcall(compress, data)
    if ok and type(result) == "string" then return result end
    return nil, tostring(result or "LZ4 compression failed")
end
function runProtected8(data)
    local compress = ab and ab.zstdcompress
    if type(compress) ~= "function" then return nil, "ZSTD compression is unavailable" end
    local ok, result = pcall(compress, data)
    if ok and type(result) == "string" then return result end
    return nil, tostring(result or "ZSTD compression failed")
end
function runProtected9(a)
    local b, c
    local function processItems3(du)
        local dv = du.Properties.Source or du.Properties.ContentText
        local dw, dx, dy
        if dv then
            dy = du.Properties.Name or "unnamed"
            dw = du.ClassName .. ":" .. dy
            if not b[dw] then
                b[dw] = {}
            end
            dx = b[dw]
            table.insert(dx, dv)
        end
        local dz
        dw = ipairs(dz)
        local ea = table.pack(dw(dz, 0))
        local eb = table.unpack(ea, 1, ea.n)
        if not (eb == nil) then
            dx = eb
            while true do
                c(table.unpack(ea, 2, ea.n))
                ea = table.pack(dw(dz, dx))
                eb = table.unpack(ea, 1, ea.n)
                if eb ~= nil then
                    dx = eb
                    continue
                end
                break
            end
        end
        return du, dv, dw, dz, eb, table.unpack(ea, 1, ea.n)
    end
    local d, readNumber, readNumber2, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, df, read3, dg, dh, di

        local processX39
        local processX363

        processX39 = function()
            while true do
                m = ipairs(n)
                c = 0
                di = table.pack(m(n, c))
                o = table.unpack(di, 1, di.n)
                c = o
                r = r(s, t)
                s = "(µ/ý"

                if not (r == s) then
                    di = table.pack(m(n, c))
                    c = table.unpack(di, 1, di.n)
                    dg = s
                    read3 = s.read(dg)
                    dh = string
                else
                    break
                end
            end
        end

        processX363 = function()
            if not (r == s) then
                di = table.pack(m(n, c))
                c = table.unpack(di, 1, di.n)
                dg = s
                read3 = s.read(dg)
                dh = string
                processX39()
            end
        end
    do
        local dj = {}
        b = dj
        d = ar(a, false)
        local dk = {}
        local dl = {}
        do
            if d:read(8) ~= "<roblox!" or d:read(6) ~= "ÿ\r\n\026\n" then
                return b, "Invalid header"
            else
                if d:read(2) ~= string.char(0) .. string.char(0) then
                    return b, "Invalid version"
                else
                    readNumber = d:readNumber("<i4")
                    readNumber2 = d:readNumber("<i4")
                    local dm = {}
                    e = dm
                    local dn = {}
                    f = dn
                    local dp = {}
                    g = dp
                    local dq = {}
                    h = dq
                    i = "END" .. string.char(0)
                    local dr = {
                        [i] = true,
                        INST = true,
                        META = true,
                        PRNT = true,
                        PROP = true,
                        SIGN = true,
                        SSTR = true,
                    }
                    j = dr
                    k = next
                    l = dr
                    n = next(dr, nil)
                    if not (n == nil) then
                        m = n
                        local ds = {}
                        while true do
                            h[n] = ds
                            n = k(l, m)
                            if n ~= nil then
                                m = n
                                continue
                            end
                            break
                        end
                    end
                    c = 0
                    if d:read(8) ~= string.char(0, 0, 0, 0, 0, 0, 0, 0) then
                        return b, "Invalid header"
                    else
                        l = nil
                        k = 1
                        local dt = {}
                        n = dt
                        dt.InternalID = 1
                        n.Header = d:read(4)
                        m = n
                        c = j[n.Header]
                        if not c then
                            c = "Invalid chunk"
                            return b, "Invalid chunk"
                        else
                            c = d
                            n = d:read(16, false)
                            c = string.unpack("<I4", string.sub(n, 1, 4))
                            o = string.unpack("<I4", string.sub(n, 5, 8))
                            p = string.sub(n, 13, 16)
                            if c == 0 then
                                q = d:read(o + 12)
                                local __brk50 = false
                                while true do
                                    r = ar(q, false)
                                    while true do
                                        m.Data = r
                                        r = table.insert
                                        s = h[m.Header]
                                        t = m
                                        r(s, m)
                                        l = m
                                        while true do
                                            r = l
                                            if r then
                                                s = l.Header
                                                r = s == i
                                            end
                                            if r then
                                                processX39()
                                            else
                                                k = k + 1
                                                if k % 50 == 0 then
                                                    at.Heartbeat:Wait()
                                                    n = dk
                                                    dk.InternalID = k
                                                    c = d:read(4)
                                                    n.Header = c
                                                    m = n
                                                    c = j[n.Header]
                                                    if not c then
                                                        c = "Invalid chunk"
                                                        return b, c
                                                    else
                                                        c = d
                                                        n = d:read(16, false)
                                                        c = string.unpack("<I4", string.sub(n, 1, 4))
                                                        o = string.unpack("<I4", string.sub(n, 5, 8))
                                                        p = string.sub(n, 13, 16)
                                                        if c == 0 then
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            r = table.insert
                                                            s = h[m.Header]
                                                            t = m
                                                            r(s, m)
                                                            l = m
                                                            continue
                                                        else
                                                            d:seek(12)
                                                            r = d:read(c)
                                                            if p == "(µ/ý" then
                                                                q = av(r)
                                                                m.Data = ar(q, false)
                                                                r = table.insert
                                                                s = h[m.Header]
                                                                t = m
                                                                r(s, m)
                                                                l = m
                                                                continue
                                                            else
                                                                x = "\000\000\000\000"
                                                                s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                                                u = au
                                                                w = o
                                                                di = table.pack(pcall(au, s, o))
                                                                v = table.unpack(di, 1, di.n)
                                                                if v then
                                                                    u = table.unpack(di, 2, di.n)
                                                                    w = "number"
                                                                    x = "string"
                                                                    v = false
                                                                    q = u
                                                                    m.Data = ar(u, false)
                                                                    r = table.insert
                                                                    s = h[m.Header]
                                                                    t = m
                                                                    r(s, m)
                                                                    l = m
                                                                    continue
                                                                else
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                n = dl
                                                dl.InternalID = k
                                                p = 4
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                o = n.Header
                                                c = j[o]
                                                n = not c
                                                if not n then
                                                    c = d
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    q = nil
                                                    if c == 0 then
                                                        q = d:read(o + 12)
                                                        m.Data = ar(q, false)
                                                        r = table.insert
                                                        w = q % x
                                                        x = 0
                                                    else
                                                        r = d.seek
                                                        r(d, 12)
                                                        t = 12
                                                        m = 0
                                                        n = ipairs
                                                        c = h.INST
                                                        s = 0
                                                        processX363()
                                                    end
                                                end
                                                __brk50 = true
                                                break
                                            end
                                        end
                                        if __brk50 then
                                            break
                                        end
                                        if v then
                                            u = table.unpack(di, 2, di.n)
                                            q = u
                                        else
                                            w = r
                                            x = o
                                            v = au(r, o)
                                            q = v
                                        end
                                        r = ar(q, false)
                                    end
                                    if __brk50 then
                                        break
                                    end
                                    w = r
                                    x = o
                                    v = au(r, o)
                                    q = v
                                end
                            else
                                d:seek(12)
                                t = c
                                local __cont52 = false
                                local __brk53 = false
                                while true do
                                    r = d:read(t)
                                    if p == "(µ/ý" then
                                        t = r
                                        q = av(r)
                                        while true do
                                            m.Data = ar(q, false)
                                            s = h[m.Header]
                                            t = m
                                            table.insert(s, m)
                                            l = m
                                            while true do
                                                r = l
                                                if r then
                                                    s = l.Header
                                                    r = s == i
                                                end
                                                if r then
                                                    processX39()
                                                else
                                                    k = k + 1
                                                    m = k % 50
                                                    n = 0
                                                    if m == 0 then
                                                        at.Heartbeat:Wait()
                                                        n = dk
                                                        dk.InternalID = k
                                                        c = d:read(4)
                                                        n.Header = c
                                                        m = n
                                                        c = j[n.Header]
                                                        if not c then
                                                            c = "Invalid chunk"
                                                            return b, c
                                                        else
                                                            c = d
                                                            n = d:read(16, false)
                                                            c = string.unpack("<I4", string.sub(n, 1, 4))
                                                            o = string.unpack("<I4", string.sub(n, 5, 8))
                                                            p = string.sub(n, 13, 16)
                                                            if c ~= 0 then
                                                                d:seek(12)
                                                                t = c
                                                                __cont52 = true
                                                                break
                                                            end
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            s = h[m.Header]
                                                            t = m
                                                            table.insert(s, m)
                                                            l = m
                                                            continue
                                                        end
                                                    end
                                                    break
                                                end
                                            end
                                            if __cont52 then
                                                break
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            p = 4
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            o = n.Header
                                            c = j[o]
                                            n = not c
                                            if not n then
                                                c = d
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                t = 8
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                t = o + 12
                                                q = d:read(t)
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                        if __cont52 then
                                            __cont52 = false
                                            continue
                                        end
                                        if __brk53 then
                                            break
                                        end
                                        d:seek(12)
                                        t = c
                                        continue
                                    end
                                    s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                    u = au
                                    di = table.pack(pcall(au, s, o))
                                    if table.unpack(di, 1, di.n) then
                                        u = table.unpack(di, 2, di.n)
                                        w = "number"
                                        x = "string"
                                        v = false
                                        q = u
                                        m.Data = ar(u, false)
                                        s = h[m.Header]
                                        t = m
                                        table.insert(s, m)
                                        l = m
                                    else
                                        w = r
                                        x = o
                                        v = au(r, o)
                                        q = v
                                        t = false
                                        m.Data = ar(v, false)
                                        s = table
                                    end
                                    while true do
                                        r = l
                                        if r then
                                            s = l.Header
                                            r = s == i
                                        end
                                        if r then
                                            processX39()
                                        else
                                            k = k + 1
                                            if k % 50 == 0 then
                                                at.Heartbeat:Wait()
                                                n = dk
                                                dk.InternalID = k
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                c = j[n.Header]
                                                if not c then
                                                    c = "Invalid chunk"
                                                    return b, c
                                                else
                                                    c = d
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    if c ~= 0 then
                                                        dh.char(0)
                                                        w = c
                                                        v = table.unpack(di, 2, di.n)
                                                        w(v)
                                                        return v, w
                                                    end
                                                    q = d:read(o + 12)
                                                    m.Data = ar(q, false)
                                                    s = h[m.Header]
                                                    t = m
                                                    table.insert(s, m)
                                                    l = m
                                                    continue
                                                end
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            p = 4
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            o = n.Header
                                            c = j[o]
                                            n = not c
                                            if not n then
                                                c = d
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                t = 8
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                q = d:read(o + 12)
                                                m.Data = ar(q, false)
                                                s = h[m.Header]
                                                t = m
                                                table.insert(s, m)
                                                l = m
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                    end
                                    if __brk53 then
                                        break
                                    end
                                end
                            end
                        end
                        c = "Invalid chunk"
                        return b, "Invalid chunk"
                    end
                end
            end
        end
        y[z] = df
        if s == t then
            s = at.Heartbeat
            t = s
            s = s.Wait
            s(t)
        end
        s = table.unpack(di, 2, di.n).Data
        return b
    end
end
