using ParameterisedModule
using Test

Functor = Function

    # Write your own tests here.

    # :(@sig struct S{A}
#     x :: Int
#     y :: A
#     struct K end
# end) |> (x -> macroexpand(ParameterisedModule, x)) |> println


@testset "I'm here?" begin

@sig struct S{A}
    x :: Int
    y :: A
    struct K end
end

println(S)

# :(@structure struct S{String}
#     struct K
#         x :: Int
#     end
#     x = 2
#     y = "2"
# end) |> (x -> macroexpand(ParameterisedModule, x)) |> println

mod1 = @structure struct S{String}
    struct K
        x :: Int
    end
    x = 2
    y = "2"
end

@test mod1.x == 2
@test mod1.y == "2"
@test_throws Any mod1.x = 3


@test_throws Any begin
    @structure struct S{Nothing}
    struct K_ end
        K = K_
        x = 0
        y = "2" # should be nothing
    end
end


@sig struct Numeric
    (+) :: Function
    (-) :: Function
end

mod3 = @structure struct Numeric
    a + b = "$a + $b"
    a - b = "$a - $b"
end


@test mod3.:+(1, 2) == "1 + 2"
@test mod3.:-(1, 2) == "1 - 2"

@open Numeric mod3 begin
    @test 1 + 2 == "1 + 2"
end


using ParameterisedModule

# this is the module type declaration
@sig struct NatAlgebra
    struct Eltype end # this is type declaration
    succ :: Function
    zero :: Eltype
end

# make a module `num_nat`, whose module type is NatAlgebra
num_nat = @structure struct NatAlgebra
    Eltype  = Int
    succ(x) = x + 1
    zero    = 0
end

@open NatAlgebra num_nat begin
    println(succ(succ(zero))) # 2
end

@test_throws UndefVarError println(succ(succ(zero)))
# ERROR: UndefVarError: succ not defined

str_nat = @structure struct NatAlgebra
    Eltype  = String
    succ(x) = "succ($x)"
    zero    = "zero"
end

@open NatAlgebra str_nat begin
    println(succ(succ(zero))) # succ(succ(zero))
end

@sig struct TF{Eltype}
    e :: Eltype
end

TFZero(nat :: NatAlgebra) =
    @structure struct TF{nat.Eltype}
        e = nat.zero
    end

word_algebra =
    @structure struct NatAlgebra
        Eltype = Functor
        zero = TFZero
        succ(T1) =
            function (N::NatAlgebra)
                @structure struct TF{N.Eltype}
                    e = N.succ(T1(N).e)
                end
            end
    end

@sig struct H
    h :: Functor
end

word_algebra.succ(TFZero)(num_nat) |> println

HTFC(N::NatAlgebra) =
    @structure struct H
        h(T) = T(N).e
    end

@open H HTFC(num_nat) begin
    @test h(word_algebra.zero) == num_nat.zero
    case(x::Functor) =
        h(word_algebra.succ(x)) == num_nat.succ(h(x))

    words = Functor[TFZero]
    for i = 1:100
        push!(words, word_algebra.succ(words[end]))
    end
    @test all(words) do x; case(x) end
end
end
