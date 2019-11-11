using Documenter, ParameterisedModule

makedocs(;
    modules=[ParameterisedModule],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/thautwarm/ParameterisedModule.jl/blob/{commit}{path}#L{line}",
    sitename="ParameterisedModule.jl",
    authors="thautwarm",
    assets=String[],
)

deploydocs(;
    repo="github.com/thautwarm/ParameterisedModule.jl",
)
