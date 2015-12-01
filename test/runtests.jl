using Variants
using Base.Test

# Constructors

x1 = Variant{Int,Int}(1, Val{true})
x2 = Variant{Int,Int}(2, true)
x3 = Variant{Int,Int}(3, Val{false})
x4 = Variant{Int,Int}(4, false)
@test_throws VariantException Variant{Int,Int}(5)
x6 = Variant{Int,Char}(6)
x7 = Variant{Int,Char}(7, Val{true})
x8 = Variant{Int,Char}(8, true)
@test_throws MethodError Variant{Int,Char}(9, Val{false})
@test_throws TypeError Variant{Int,Char}(10, false)
xa = Variant{Int,Char}('a')
@test_throws MethodError Variant{Int,Char}('b', Val{true})
@test_throws TypeError Variant{Int,Char}('c', true)
xd = Variant{Int,Char}('d', Val{false})
xe = Variant{Int,Char}('e', false)

@test lefttype(Variant{Int,Int}) === Int
@test righttype(Variant{Int,Int}) === Int
@test lefttype(Variant{Int,Char}) === Int
@test righttype(Variant{Int,Char}) === Char

# Basic properties

@test isleft(x1) && isleft(x2)
@test isright(x3) && isright(x4)
@test isleft(x6) && isleft(x7) && isleft(x8)
@test isright(xa) && isright(xd) && isright(xe)

@test getleft(x1) == 1
@test_throws VariantException getright(x1)
@test getleft(x1, 42) == 1
@test getright(x1, 42) == 42
@test isequal(getleft_null(x1), Nullable(1))
@test isequal(getright_null(x1), Nullable{Int}())

@test_throws VariantException getleft(x3)
@test getright(x3) == 3
@test getleft(x3, 42) == 42
@test getright(x3, 42) == 3
@test isequal(getleft_null(x3), Nullable{Int}())
@test isequal(getright_null(x3), Nullable(3))

@test getleft(x6) == 6
@test_throws VariantException getright(x6)
@test getleft(x6, 42) == 6
@test getright(x6, 42) == 42
@test isequal(getleft_null(x6), Nullable(6))
@test isequal(getright_null(x6), Nullable{Int}())

@test_throws VariantException getleft(xa)
@test getright(xa) == 'a'
@test getleft(xa, 'z') == 'z'
@test getright(xa, 'z') == 'a'
@test isequal(getleft_null(xa), Nullable{Char}())
@test isequal(getright_null(xa), Nullable('a'))

@test isequal(x1, Variant{Int,Int}(1, true))
@test !isequal(x1, Variant{Int,Int}(1, false))
@test !isequal(x3, Variant{Int,Int}(3, true))
@test isequal(x3, Variant{Int,Int}(3, false))

@test isequal(x6, Variant{Int,Char}(6))
@test !isequal(x6, Variant{Int,Char}('a'))
@test !isequal(xa, Variant{Int,Char}(6))
@test isequal(xa, Variant{Int,Char}('a'))

@test hash(x1) == hash(Variant{Int,Int}(1, true))
@test hash(x1) != hash(Variant{Int,Int}(1, false))
@test hash(x3) != hash(Variant{Int,Int}(3, true))
@test hash(x3) == hash(Variant{Int,Int}(3, false))

@test hash(x6) == hash(Variant{Int,Char}(6))
@test hash(x6) != hash(Variant{Int,Char}('a'))
@test hash(xa) != hash(Variant{Int,Char}(6))
@test hash(xa) == hash(Variant{Int,Char}('a'))

@test !isless(x1, Variant{Int,Int}(1, true))
@test isless(x1, Variant{Int,Int}(1, false))
@test !isless(x3, Variant{Int,Int}(3, true))
@test !isless(x3, Variant{Int,Int}(3, false))

@test !isless(x6, Variant{Int,Char}(6))
@test isless(x6, Variant{Int,Char}('a'))
@test !isless(xa, Variant{Int,Char}(6))
@test !isless(xa, Variant{Int,Char}('a'))

int = string(Int)   # either "Int32" or "Int64"
@test string(x1) == "Variant{$int,$int}(left:1)"
@test string(x3) == "Variant{$int,$int}(right:3)"
@test string(x6) == "Variant{$int,Char}(left:6)"
@test string(xa) == "Variant{$int,Char}(right:'a')"

# Non-trivial nesting

typealias V1 Variant{Int, Char}
typealias V2 Variant{Float64, AbstractString}
typealias V3 Variant{V1, V2}
v1a = V1(1)
v1b = V1('b')
v2a = V2(3.0)
v2b = V2("d")
v3aa = V3(v1a)
v3ab = V3(v1b)
v3ba = V3(v2a)
v3bb = V3(v2b)
@test getleft(getleft(v3aa)) == 1
@test getright(getleft(v3ab)) == 'b'
@test getleft(getright(v3ba)) == 3.0
@test getright(getright(v3bb)) == "d"

# Higher order functions

@test variant(Variant{Int,Int}(4,true)) == 4
@test variant(Variant{Int,Int}(4,false)) == 4

@test variant(+, -, Variant{Int,Int}(4,true)) == 4
@test variant(+, -, Variant{Int,Int}(4,false)) == -4

v1arr = V1[v1a, v1b, v1b]
v2arr = V2[v2b, v2a]
@test lefts(v1arr) == [1]
@test rights(v1arr) == ['b', 'b']
@test lefts(v2arr) == [3.0]
@test rights(v2arr) == ["d"]
@test partition_variants(v1arr) == (lefts(v1arr), rights(v1arr))
@test partition_variants(v2arr) == (lefts(v2arr), rights(v2arr))

typealias V4 Variant{Vector{V1}, Vector{V2}}
v4a = V4(v1arr)
v4b = V4(v2arr)
@test variant(length, sum, v4a) == 3
@test variant(max, length, v4b) == 2
