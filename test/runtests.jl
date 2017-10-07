using ModelerToolbox, JLD2
using Base.Test

type Lemons
    n::Int
    color::Symbol
end

ModelerToolbox.jld_fn(::Lemons) = Pkg.dir("ModelerToolbox", "test", "lemons.jld")
ModelerToolbox.group_keys(l::Lemons) = (l.n, l.color)

type Apples
    n::Int
    color::Symbol
end

ModelerToolbox.jld_fn(::Apples) = Pkg.dir("ModelerToolbox", "test", "apples.jld")
ModelerToolbox.group_keys(a::Apples) = a.n

# create some test objects
l1 = Lemons(1, :yellow)
l2 = Lemons(3, :yellow)
l3 = Lemons(1, :greenish)
a1 = Apples(1, :red)
a2 = Apples(3, :yellow)
a3 = Apples(1, :green)  # NOTE: this should have the same key as a1

# delete the files if they already exist
isfile(jld_fn(l1)) && rm(jld_fn(l1))
isfile(jld_fn(a1)) && rm(jld_fn(a1))

# make sure we can init the file
init_jld(l1)
@test isfile(jld_fn(l1))
@test !isfile(jld_fn(a1))

init_jld(a1)
@test isfile(jld_fn(a1))

# make sure the group was created for the first object
@test groupname(l1) == ("group1", true, true)
@test groupname(l2) == ("group2", false, false)
# NOTE: repeat group2 because it was never created
@test groupname(l3) == ("group2", false, false)

# make sure the group was created for the first object
@test groupname(a1) == ("group1", true, true)
@test groupname(a2) == ("group2", false, false)
@test groupname(a3) == ("group1", true, true)

# now make all the groups
@test groupname!(l1) == ("group1", true, true)
@test groupname!(l2) == ("group2", true, true)
@test groupname!(l3) == ("group3", true, true)

# make sure the group was created for the first object
@test groupname!(a1) == ("group1", true, true)
@test groupname!(a2) == ("group2", true, true)
@test groupname!(a3) == ("group1", true, true)

# test with_group and with_file
@test length(with_group(names, l1)) == 1
@test sort(with_file(names, l1)) == ["group1", "group2", "group3", "groups"]

# test delete_group!
delete_group!(l1)
jldopen(jld_fn(l1), "r") do f
    @test !exists(f, "group1")

    # also make sure it was removed from the map
    group_map = read(f, "groups")
    @test !haskey(group_map, group_keys(l1))
end

# test write_jld
write_jld(l1, "foo", "bar")
jldopen(jld_fn(l1), "r") do f
    # groupname for l1 is now 4 because we deleted group1 above
    @test exists(f, "group4")
    g = f["group4"]
    @test exists(g, "foo")
    @test read(g, "foo") == "bar"
end

# test read_jld
@test read_jld(l1, "foo") == "bar"

# test delete_jld!
delete_jld!(l1, "foo")
jldopen(jld_fn(l1), "r") do f
    # groupname for l1 is now 4 because we deleted group1 above
    g = f["group4"]
    @test !exists(g, "foo")
end

@test_throws ErrorException delete_jld!(l1, "foo")

# test haskey_jld
@test !haskey_jld(l1, "foo")
write_jld(l1, "bing", "bong")
@test haskey_jld(l1, "bing")

# test names_jld
@test sort(names_jld(l1)) == ["bing", "visted"]

# test groups
grps = groups(l1)
@test length(grps) == 3
@test sort(collect(values(grps))) == ["group2", "group3", "group4"]
@test sort(collect(values(groups(a1)))) == ["group1", "group2"]


# test write_jld!
write_jld!(l1, bing=42)
@test read_jld(l1, "bing") == 42

write_jld!(l1, hello="world")
@test read_jld(l1, "hello") == "world"
