
<a id='JLD-tools-1'></a>

## JLD tools


I often find myself working with many different parameterizations of a given model. I often need to store things like initial guesses, solutions, etc. so I can come back to the model and pick up right where I left off. In the past this has involved one of two things:


1. Some ad hoc file naming system I use to identify which version of which model a particular object belongs to
2. A variation of the same where I at least collect objects for the same model in a dedicated folder


The main problem with this approach is that when I'm doing research, I don't usually know all the permutations of parameters and models that I'll need. This makes it very difficult to support this type of ad hoc system as the project expands. What I really needed was something that scales with the project.


ModelerToolbox defines a set of routines that makes scalable, per model data storage easy. The routines are built on top of JLD.jl, which in turn uses HDF5.jl for storage.


The user of this package will need to implement their own methods for two key functions exported by ModelerToolbox:


1. `jld_fn(::T)`: gives the full path to the jld file that should be used when storing data for objects of type `T`
2. `group_keys(::T)`: gives a unique key that allows you to distinguish one instance of type `T` from another.


Once these two methods have been defined for your type `T`, ModelerToolbox provides the following methods (see docstrings for details on what each of them does):



<a id='ModelerToolbox.init_jld-Tuple{Any}' href='#ModelerToolbox.init_jld-Tuple{Any}'>#</a>
**`ModelerToolbox.init_jld`** &mdash; *Method*.



```julia
init_jld(x, [force=false])
```

Initialize the jld_file for objects of type `typeof(x)`. This creates the file (if needed) and ensures that a `groups` dataset exists and constructs a group for the instance `x`.

If `force` is `true` any existing file is overwritten and the above operations are performed.

This should only be called by users when they want to completely reconstruct the jld file.

<a id='ModelerToolbox.groupname-Tuple{Any}' href='#ModelerToolbox.groupname-Tuple{Any}'>#</a>
**`ModelerToolbox.groupname`** &mdash; *Method*.



```julia
groupname(x::T)
```

Returns a tuple `(name, group_map_exists, group_exists)` specifying the `name` of the group for x, whether a map from `group_keys(x)` to a group name exists in the jld file, and whether or not a group with `name` exists in the jld file. Mostly an internal function

<a id='ModelerToolbox.groupname!-Tuple{Any}' href='#ModelerToolbox.groupname!-Tuple{Any}'>#</a>
**`ModelerToolbox.groupname!`** &mdash; *Method*.



```julia
groupname!(x::T)
```

Returns the same as `groupname(x)`, but also creates the group map (if `group_map_exists == false`) and the group (if `group_exists == false`).

<a id='ModelerToolbox.delete_group!-Tuple{Any}' href='#ModelerToolbox.delete_group!-Tuple{Any}'>#</a>
**`ModelerToolbox.delete_group!`** &mdash; *Method*.



```julia
delete_group!(x)
```

Delete the jld group associated with the instance of `x` and remove its entry from the group map.

<a id='ModelerToolbox.with_group-Tuple{Any,Any}' href='#ModelerToolbox.with_group-Tuple{Any,Any}'>#</a>
**`ModelerToolbox.with_group`** &mdash; *Method*.



```julia
with_group(func!::Function, x)
```

With the jld group corresponding to the instance `x` as `g`, call `func!(g)`. This is a core method that is used to interact with the group for an object.

<a id='ModelerToolbox.@with_group' href='#ModelerToolbox.@with_group'>#</a>
**`ModelerToolbox.@with_group`** &mdash; *Macro*.



```julia
macro with_group(func)
```

Wrap the body of a function `func` in a call to `with_group`. This is best understood by example.

```julia
@with_group write_jld(x, nm, obj) = write(g, nm, obj)
```

is equivalent to

```julia
write_jld(x, nm, obj) = with_group(g -> write(g, nm, obj), x)
```

<a id='ModelerToolbox.with_file-Tuple{Any,Any}' href='#ModelerToolbox.with_file-Tuple{Any,Any}'>#</a>
**`ModelerToolbox.with_file`** &mdash; *Method*.



```julia
with_file(func!::Function, x)
```

With the jld file object for objects of type `typeof(x)` as `f`, call `func!(f)`. This is a core method that is used to interact with the jld file as a whole.

<a id='ModelerToolbox.@with_file' href='#ModelerToolbox.@with_file'>#</a>
**`ModelerToolbox.@with_file`** &mdash; *Macro*.



```julia
macro with_group(func)
```

Wrap the body of a function `func` in a call to `with_file`. This is best understood by example.

```julia
@with_file foobar(x, y) = foobar(f, y)
```

is equivalent to

```julia
foobar(x, nm, obj) = with_file(f -> foobar(y), x)
```

Here's the same example from the REPL (note that some comments have been removed from the output)

<a id='ModelerToolbox.write_jld-Tuple{Any,Any,Any}' href='#ModelerToolbox.write_jld-Tuple{Any,Any,Any}'>#</a>
**`ModelerToolbox.write_jld`** &mdash; *Method*.



```julia
write_jld(x, nm, obj)
```

Write the object `obj` `x`'s jld group under name `nm`

<a id='ModelerToolbox.write_jld!-Tuple{Any,Any,Any}' href='#ModelerToolbox.write_jld!-Tuple{Any,Any,Any}'>#</a>
**`ModelerToolbox.write_jld!`** &mdash; *Method*.



```julia
write_jld!(x, nm, obj)
```

Write the object `obj` `x`'s jld group under name `nm`. This routine will overwrite any existing object with name `nm` in the group.

<a id='ModelerToolbox.read_jld-Tuple{Any,Any}' href='#ModelerToolbox.read_jld-Tuple{Any,Any}'>#</a>
**`ModelerToolbox.read_jld`** &mdash; *Method*.



```julia
read_jld(x, nm)
```

Read the object with `nm` from  `x`'s jld group

<a id='ModelerToolbox.delete_jld!-Tuple{Any,Any}' href='#ModelerToolbox.delete_jld!-Tuple{Any,Any}'>#</a>
**`ModelerToolbox.delete_jld!`** &mdash; *Method*.



```julia
delete_jld!(x, dataset)
```

Delete the object with name `dataset` from `x`'s jld group

<a id='ModelerToolbox.haskey_jld-Tuple{Any,Any}' href='#ModelerToolbox.haskey_jld-Tuple{Any,Any}'>#</a>
**`ModelerToolbox.haskey_jld`** &mdash; *Method*.



```julia
haskey_jld(x, dataset)
```

Check if the jld group for `x` has an object named `dataset`

<a id='ModelerToolbox.names_jld-Tuple{Any}' href='#ModelerToolbox.names_jld-Tuple{Any}'>#</a>
**`ModelerToolbox.names_jld`** &mdash; *Method*.



```julia
names_jld(x)
```

List all the names in `x`'s jld group

<a id='ModelerToolbox.groups-Tuple{Any}' href='#ModelerToolbox.groups-Tuple{Any}'>#</a>
**`ModelerToolbox.groups`** &mdash; *Method*.



```julia
groups(x)
```

Return the dict mapping keys to jld group names for all objects of type `typeof(x)`. If the dict doesn't yet exist, it is created, along with a group for the instance `x`.



