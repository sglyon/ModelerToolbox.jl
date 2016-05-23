## JLD tools

I often find myself working with many different parameterizations of a given
model. I often need to store things like initial guesses, solutions, etc. so I
can come back to the model and pick up right where I left off. In the past this
has involved one of two things:

1. Some ad hoc file naming system I use to identify which version of which
model a particular object belongs to
2. A variation of the same where I at least collect objects for the same model
in a dedicated folder

The main problem with this approach is that when I'm doing research, I don't
usually know all the permutations of parameters and models that I'll need. This
makes it very difficult to support this type of ad hoc system as the project
expands. What I really needed was something that scales with the project.

ModelerToolbox defines a set of routines that makes scalable, per model data
storage easy. The routines are built on top of JLD.jl, which in turn uses
HDF5.jl for storage.

The user of this package will need to implement their own methods for two key
functions exported by ModelerToolbox:

1. `jld_fn(::T)`: gives the full path to the jld file that should be used when
storing data for objects of type `T`
2. `group_keys(::T)`: gives a unique key that allows you to distinguish one
instance of type `T` from another.

Once these two methods have been defined for your type `T`, ModelerToolbox
provides the following methods (see docstrings for details on what each of
them does):

```@meta
CurrentModule = ModelerToolbox
```


```@docs    
init_jld(x)
groupname(x)
groupname!(x)
delete_group!(x)
with_group(f!, x)
@with_group(f!, x)
with_file(f!, x)
@with_file(f!, x)
write_jld(x, nm, obj)
write_jld!(x, nm, obj)
read_jld(x, dataset)
delete_jld!(x, dataset)
haskey_jld(x, dataset)
names_jld(x)
groups(x)
```

```@meta
CurrentModule = Main
```
