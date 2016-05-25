export
    # methods that must be overloaded
    jld_fn, group_keys,

    # convenience methods
    groupname, groupname!, with_group, @with_group, with_file, @with_file,
    groups, init_jld,

    # core api methods
    write_jld, write_jld!, read_jld, delete_jld!, names_jld, delete_group!,
    groups, haskey_jld

# just define _function_ here so others can define methods
function jld_fn end
function group_keys end

"""
```julia
init_jld(x, [force=false])
```

Initialize the jld_file for objects of type `typeof(x)`. This creates the file
(if needed) and ensures that a `groups` dataset exists and constructs a group
for the instance `x`.

If `force` is `true` any existing file is overwritten and the above operations
are performed.

This should only be called by users when they want to completely reconstruct
the jld file.
"""
function init_jld(x, force::Bool=false)
    if !isfile(jld_fn(x)) || force
        # create the file and the map and first group
        jldopen(jld_fn(x), "w") do f
            grps = Dict(group_keys(x) => "group1")
            write(f, "groups", grps)
            g_create(f, "group1")
        end

        return
    end

    # we know the file exists, now we just need to make sure the map and
    # group for x exist. That's what groupname!(x) is for!
    groupname!(x)
    return
end

"""
```julia
groupname(x::T)
```

Returns a tuple `(name, group_map_exists, group_exists)` specifying the `name`
of the group for x, whether a map from `group_keys(x)` to a group name exists
in the jld file, and whether or not a group with `name` exists in the jld file.
Mostly an internal function
"""
function groupname(x)
    # NOTE: can't use `groups` method here because we might get stuck in an
    #       infinite recursion when `init_jld` calls this routine (via a call
    #       to `groupname!`)
    grps = jldopen(jld_fn(x), "r+") do f
        if exists(f, "groups")
            read(f, "groups")
        else
            # make sure group1 doesn't already exist
            if exists(f, "group1")
                delete!(f, "group1")
            end
            return "group1", false, false
        end
    end

    # HACK to return if grps isn't a Dict
    if isa(grps, Tuple)
        return grps
    end

    if haskey(grps, group_keys(x))
        name = grps[group_keys(x)]
        group_map_exists = true

        group_exists = jldopen(jld_fn(x), "r") do f
            exists(f, name)
        end

        return name, group_map_exists, group_exists
    else
        # get new unique name
        group_nums = Int[parse(Int, x[6:end]) for x in values(grps)]
        name = string("group", maximum(group_nums) + 1)

        # the mapping entry didn't exist, and neither does the group
        return name, false, false
    end
end

"""
```julia
groupname!(x::T)
```

Returns the same as `groupname(x)`, but also creates the group map (if
`group_map_exists == false`) and the group (if `group_exists == false`).
"""
function groupname!(x)
    name, group_map_exists, group_exists = groupname(x)

    # if either the map or group doesn't exist, we need to do _something_ with
    # the file
    if !group_map_exists || !group_exists
        # NOTE: can't use with_file here because we might get stuck in an
        #       infinite recursion due to the call of this routine from within
        #       init_jld
        jldopen(jld_fn(x), "r+") do f

            if !group_map_exists
                if exists(f, "groups")
                    # get current groups
                    groups = read(f, "groups")

                    # add this name
                    groups[group_keys(x)] = name

                    # delete the groups object, then update it with the new one
                    delete!(f, "groups")
                else
                    groups = Dict(group_keys(x) => name)
                end
                write(f, "groups", groups)
            end

            if !group_exists
                # create the group
                g_create(f, name)
            end
        end
    end

    # group_map_exists, group_exists are both true now
    return name, true, true
end


"""
```julia
with_group(func!::Function, x)
```

With the jld group corresponding to the instance `x` as `g`, call `func!(g)`.
This is a core method that is used to interact with the group for an object.
"""
function with_group(func!::Function, x)
    init_jld(x)
    jldopen(jld_fn(x), "r+") do f
        g = g_open(f, groupname!(x)[1])
        out = func!(g)
        close(g)
        out
    end
end

"""
```julia
with_file(func!::Function, x)
```

With the jld file object for objects of type `typeof(x)` as `f`, call
`func!(f)`. This is a core method that is used to interact with the jld file
as a whole.
"""
function with_file(func!::Function, x)
    init_jld(x)
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

"""
```julia
macro with_group(func)
```

Wrap the body of a function `func` in a call to `with_group`. This is best
understood by example.

```julia
@with_group write_jld(x, nm, obj) = write(g, nm, obj)
```

is equivalent to

```julia
write_jld(x, nm, obj) = with_group(g -> write(g, nm, obj), x)
```
"""
macro with_group(ex)
    f, args, body = _get_f_args_body(ex)
    :($(esc(f))($(args...)) = with_group(g -> $body, $(args[1])))
end

"""
```julia
macro with_group(func)
```

Wrap the body of a function `func` in a call to `with_file`. This is best
understood by example.

```julia
@with_file foobar(x, y) = foobar(f, y)
```

is equivalent to

```julia
foobar(x, nm, obj) = with_file(f -> foobar(y), x)
```
"""
macro with_file(ex)
    f, args, body = _get_f_args_body(ex)
    :($(esc(f))($(args...)) = with_file(f -> $body, $(args[1])))
end

"""
```julia
write_jld(x, nm, obj)
```

Write the object `obj` `x`'s jld group under name `nm`
"""
@with_group write_jld(x, nm, obj) = write(g, nm, obj)

"""
```julia
read_jld(x, nm)
```

Read the object with `nm` from  `x`'s jld group
"""
@with_group read_jld(x, dataset) = read(g, dataset)

"""
```julia
delete_jld!(x, dataset)
```

Delete the object with name `dataset` from `x`'s jld group
"""
@with_group delete_jld!(x, dataset) = delete!(g, dataset)

"""
```julia
haskey_jld(x, dataset)
```

Check if the jld group for `x` has an object named `dataset`
"""
@with_group haskey_jld(x, dataset) = exists(g, dataset)

"""
```julia
names_jld(x)
```

List all the names in `x`'s jld group
"""
@with_group names_jld(x) = names(g)

"""
```julia
groups(x)
```

Return the dict mapping keys to jld group names for all objects of type
`typeof(x)`. If the dict doesn't yet exist, it is created, along with a group
for the instance `x`.
"""
@with_file groups(x) = read(f, "groups")

"""
```julia
write_jld!(x, nm, obj)
```

Write the object `obj` `x`'s jld group under name `nm`. This routine will
overwrite any existing object with name `nm` in the group.
"""
@with_group function write_jld!(x, nm, obj)
    exists(g, nm) && delete!(g, nm)
    write(g, nm, obj)
end

"""
```julia
delete_group!(x)
```

Delete the jld group associated with the instance of `x` and remove its entry
from the group map.
"""
function delete_group!(x)
    # NOTE: we don't use the macro here so that we can avoid opening the file if
    #       it isn't necessary.
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
