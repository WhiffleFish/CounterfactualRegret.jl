push!(LOAD_PATH,joinpath(@__DIR__, "..", "src"))
using Documenter
using CounterfactualRegret
using CounterfactualRegret.Games

makedocs(
    sitename = "CounterfactualRegret",
    format = Documenter.HTML(edit_link="main"),
    modules = [CounterfactualRegret, Games],
    pages = ["index.md", "api.md"]
)


deploydocs(
    repo = "github.com/WhiffleFish/CounterfactualRegret.jl",
    target = "build",
    devbranch = "main",
    push_preview = false
)
