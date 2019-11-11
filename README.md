# ParameterisedModule

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://thautwarm.github.io/ParameterisedModule.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://thautwarm.github.io/ParameterisedModule.jl/dev)
[![Build Status](https://travis-ci.com/thautwarm/ParameterisedModule.jl.svg?branch=master)](https://travis-ci.com/thautwarm/ParameterisedModule.jl)
[![Codecov](https://codecov.io/gh/thautwarm/ParameterisedModule.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/ParameterisedModule.jl)


ML parameterised modules in Julia.

# APIs

- `@sig struct ... end` : define module signatures, like `sig` in OCaml.
- `@structure struct ... end` : define module structures, like `struct` in OCaml.
- `@open ModuleType Module` : using module, like `open` in OCaml.
- `@open ModuleType Module body` : using module when evaluating `body`, like `let open` in OCaml.

# Non-Parametric Example

```julia
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

println(succ(succ(zero)))
# ERROR: UndefVarError: succ not defined

str_nat = @structure struct NatAlgebra
    Eltype  = String
    succ(x) = "succ($x)"
    zero    = "zero"
end

@open NatAlgebra str_nat begin
    println(succ(succ(zero))) # succ(succ(zero))
end
```

# Parametric Examples

An example(word-algebra) from [the section *Algebra* of Oleg's tagless final lectures](http://okmij.org/ftp/tagless-final/Algebra.html).

```julia
Functor = Function
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
    h :: Function
end

HTFC(N::NatAlgebra) =
    @structure struct H
        h(T) = T(N).e
    end

using Test
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

```