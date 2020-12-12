# TailRec

[![Build Status](https://travis-ci.org/TakekazuKATO/TailRec.jl.svg?branch=master)](https://travis-ci.org/TakekazuKATO/TailRec.jl)

# description

This package provides a macro to optimize tail-recursive functions call by rewriting them as loops. Internally, the @label and @goto macros are used to simply turn the tail recursive call into a loop with @goto.
The package does not support mutual recursion.

# Install

```
julia> ]
(@v1.5) pkg> add https://github.com/TakekazuKATO/TailRec.jl
   Updating git-repo `https://github.com/TakekazuKATO/TailRec.jl`
  Resolving package versions...
Updating `~/.julia/environments/v1.5/Project.toml`
  [f6209947] + TailRec v0.1.0 `https://github.com/TakekazuKATO/TailRec.jl#master`
Updating `~/.julia/environments/v1.5/Manifest.toml`
  [f6209947] + TailRec v0.1.0 `https://github.com/TakekazuKATO/TailRec.jl#master`
```

# How to use

The package privedes @tailrec macro. 
When @tailrec is attached before definition of the tail recursive function, the function is rewritten using a loop.

```jl
julia> using TailRec

julia> # sum of 1 to x without tail call elimination
function sumR(x, i=1)
    if x == 1
        i
    else
        sumR(x-1, i+x)
    end
end

# sum of 1 to x with tail call optimization
@tailrec function sumTCO(x, i=1)
    if x == 1
        i
    else
        sumTCO(x-1, i+x)
    end
end

julia> sumR(1000000)
ERROR: StackOverflowError:
Stacktrace:
 [1] sumR(::Int64, ::Int64) at ./REPL[57]:6 (repeats 79984 times)

julia> sumTCO(1000000)
500000500000
```


```jl
julia> @tailrec sumTCO2(x,i==1)= x==1 ? i : sumTCO2(x-1, i+x)

julia> sumTCO2(1000000)
500000500000
```


```jl
julia> @macroexpand function sumR(x, i=1)
           if x == 1
               i
           else
               sumR(x-1, i+x)
           end
       end
:(function sumR(x, i = 1)
      #= REPL[63]:1 =#
      #= REPL[63]:2 =#
      if x == 1
          #= REPL[63]:3 =#
          i
      else
          #= REPL[63]:5 =#
          sumR(x - 1, i + x)
      end
  end)

julia> @macroexpand @tailrec function sumR(x, i=1)
           if x == 1
               i
           else
               sumR(x-1, i+x)
           end
       end
:(function sumR(x, i = 1)
      $(Expr(:symboliclabel, :retry))
      begin
          #= REPL[64]:1 =#
          #= REPL[64]:2 =#
          if x == 1
              #= REPL[64]:3 =#
              i
          else
              #= REPL[64]:5 =#
              begin
                  (x, i) = (x - 1, i + x)
                  $(Expr(:symbolicgoto, :retry))
              end
          end
      end
  end)
```