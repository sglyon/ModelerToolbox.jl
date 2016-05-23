export
    # methods that must be overloaded
    jld_fn, group_keys,

    # convenience methods
    groupname, groupname!, with_group, @with_group, with_file, @with_file,
    groups,

    # core api methods
    write_jld, read_jld, delete_jld!, names_jld, delete_group!

# just define _function_ here so others can define methods
function jld_fn end
function group_keys end

# NOTE: requries `jld_fn(x)` and `group_keys(x)` to be defined for `x`
function groupname(x)
    groups = jldopen(jld_fn(x), "r") do f
        read(f, "groups")
    end

    if haskey(groups, group_keys(x))
        name = groups[group_keys(x)]
        group_map_exists = true

        group_exists = jldopen(jld_fn(x), "r") do f
            exists(f, name)
        end

        return name, group_map_exists, group_exists
    else
        # get new unique name
        group_nums = Int[parse(Int, x[6:end]) for x in values(groups)]
        name = string("group", maximum(group_nums) + 1)

        # the mapping entry didn't exist, and neither does the group
        return name, false, false
    end
end

function groupname!(x)
    name, group_map_exists, group_exists = groupname(x)

    # if the group_map and group already exist, just return the name
    if group_map_exists && group_exists
        return name
    end

    # otherwise we need to create something
    jldopen(jld_fn(x), "r+") do f

        if !group_map_exists
            # get current groups
            groups = read(f, "groups")

            # add this name
            groups[group_keys(x)] = name

            # delete the groups object, then update it with the new one
            delete!(f, "groups")
            write(f, "groups", groups)
        end

        if !group_exists
            # create the group
            g_create(f, name)
        end
    end

    return name
end

# func! should take one argument `g` that is HDF5 group for the model
# NOTE: requries `jld_fn(x)` and `groupname(x)` to be defined for `x`
function with_group(func!::Function, x)
    jldopen(jld_fn(x), "r+") do f
        g = f[groupname!(x)]
        func!(g)
    end
end

function with_file(func!::Function, x)
    jldopen(jld_fn(x), "r+") do f
        func!(f)
    end
end

function _get_f_args_body(ex::Expr)
    # try one line function definitino version
    @capture(ex, f_(args__) = body_)
    if any(map(x->x==nothing, (f, args, body)))

    # now try full `function name(args...) ` version
    @capture(ex, function f_(args__) body_ end)
    if any(map(x->x==nothing, (f, args, body)))
        error("I couldn't understand your function definition")
        end
    end

    return f, args, body
end

macro with_group(ex)
    f, args, body = _get_f_args_body(ex)
    :($(esc(f))($(args...)) = with_group(g -> $body, $(args[1])))
end

macro with_file(ex)
    f, args, body = _get_f_args_body(ex)
    :($(esc(f))($(args...)) = with_file(f -> $body, $(args[1])))
end

@with_group write_jld(x, nm, obj) = write(g, nm, obj)
@with_group read_jld(x, dataset) = read(g, dataset)
@with_group delete_jld!(x, dataset) = delete!(g, dataset)
# @with_group haskey_jld(x, dataset) = haskey(g, dataset)
@with_group names_jld(x) = names(g)
@with_file groups(m) = read(f, "groups")

function delete_group!(x)
    name, group_map_exists, group_exists = groupname(x)
    if !group_map_exists && !group_exists
        # nothing to do
        return
    end

    # we need to do something
    with_file(x) do f
        # need to delete the entry in the group map
        if group_map_exists
            # read existing map
            groups = read(f, "groups")
            
            # remove this entry
            pop!(groups, group_keys(x))

            # delete existing map
            delete!(f, "groups")

            # write updated map
            write(f, "groups", groups)
        end

        # if the group exists, delete it
        if group_exists
            delete!(f, name)
        end
    end

end
