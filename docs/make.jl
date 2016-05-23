using Documenter, ModelerToolbox

makedocs(
    doctest=false
)

run(`mkdocs build -c`)

if "publish" in ARGS
    run(`mkdocs gh-deploy -c -b gh-pages -r origin -v`)
end
