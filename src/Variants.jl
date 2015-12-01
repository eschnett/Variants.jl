module Variants

import Base: convert, show, isequal, hash, isless
export VariantException, Variant
export convert, lefttype, righttype
export isleft, isright, getleft, getright, getleft_null, getright_null, show
export isequal, hash, isless
export variant, lefts, rights, partition_variants

# Type definitions

immutable VariantException <: Exception end

immutable Variant{L,R}
    isleft::Bool
    value::Union{L,R}

    function Variant(value::L, isleft::Type{Val{true}})
        new(true, value)
    end
    function Variant(value::R, isleft::Type{Val{false}})
        new(false, value)
    end
    #=
    function Variant(value::Union{L,R}, isleft::Bool)
        if !(isleft ? isa(value, L) : isa(value, R))
            throw(VariantException())
        end
        new(isleft, value)
    end
    function Variant(value::Union{L,R})
        isleft = isa(value, L)
        isright = isa(value, R)
        if isleft && isright
            throw(VariantException())
        end
        new(isleft, value)
    end
    =#
end

function convert{L,R}(::Type{Variant{L,R}}, value, isleft::Bool)
    if isleft
        Variant{L,R}(value::L, Val{true})
    else
        Variant{L,R}(value::R, Val{false})
    end
end

function convert{L,R}(::Type{Variant{L,R}}, value)
    isleft = isa(value, L)
    isright = isa(value, R)
    if isleft == isright
        throw(VariantException())
    end
    # Variant{L,R}(value, isleft)
    if isleft
        Variant{L,R}(value::L, Val{true})
    else
        Variant{L,R}(value::R, Val{false})
    end
end

convert{L,R}(::Type{Variant{L,R}}, x::Variant{L,R}) = x

lefttype{L,R}(::Type{Variant{L,R}}) = L
righttype{L,R}(::Type{Variant{L,R}}) = R

# Low-level accessors

isleft(x::Variant) = x.isleft
isright(x::Variant) = !x.isleft

getleft{L,R}(x::Variant{L,R}) = !x.isleft ? throw(VariantException()) : x.value::L
getright{L,R}(x::Variant{L,R}) = x.isleft ? throw(VariantException()) : x.value::R

getleft{L,R}(x::Variant{L,R}, y) = !x.isleft ? convert(L, y) : x.value::L
getright{L,R}(x::Variant{L,R}, y) = x.isleft ? convert(R, y) : x.value::R

getleft_null{L,R}(x::Variant{L,R}) = !x.isleft ? Nullable{L}() : Nullable{L}(x.value::L)
getright_null{L,R}(x::Variant{L,R}) = x.isleft ? Nullable{R}() : Nullable{R}(x.value::R)

# High-level accessors

function isequal{L,R}(x::Variant{L,R}, y::Variant{L,R})
    if isleft(x) != isleft(y)
        false
    elseif isleft(x)
        getleft(x) == getleft(y)
    else
        getright(x) == getright(y)
    end
end

const variant_hashseed_left = UInt(typemax(UInt) & 0xa30e411403dcb935)
const variant_hashseed_right = UInt(typemax(UInt) & 0x5fe656f0e4d6e72d)
function hash{L,R}(x::Variant{L,R}, h::UInt)
    if isleft(x)
        hash(getleft(x), h + variant_hashseed_left)
    else
        hash(getright(x), h + variant_hashseed_right)
    end
end

function isless{L,R}(x::Variant{L,R}, y::Variant{L,R})
    if isleft(x)
        if isleft(y)
            isless(getleft(x), getleft(y))
        else
            true
        end
    else
        if isleft(y)
            false
        else
            isless(getright(x), getright(y))
        end
    end
end

function show{L,R}(io::IO, x::Variant{L,R})
    print(io, "Variant{")
    show(io, L)
    print(io, ",")
    show(io, R)
    print(io, "}(", isleft(x) ? "left" : "right", ":")
    if x.isleft
        show(io, getleft(x))
    else
        show(io, getright(x))
    end
    print(io, ")")
end

# Higher order functions

variant(x::Variant) = isleft(x) ? getleft(x) : getright(x)
variant(f, g, x::Variant) = isleft(x) ? f(getleft(x)) : g(getright(x))

function lefts{L,R}(xs::Array{Variant{L,R}})
    ls = L[]
    for x in xs
        if isleft(x)
            push!(ls, getleft(x))
        end
    end
    ls
end

function rights{L,R}(xs::Array{Variant{L,R}})
    rs = R[]
    for x in xs
        if isright(x)
            push!(rs, getright(x))
        end
    end
    rs
end

function partition_variants{L,R}(xs::Array{Variant{L,R}})
    ls = L[]
    rs = R[]
    for x in xs
        if isleft(x)
            push!(ls, getleft(x))
        else
            push!(rs, getright(x))
        end
    end
    ls, rs
end

end # module
