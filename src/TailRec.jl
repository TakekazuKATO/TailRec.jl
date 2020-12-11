module TailRec
export @tailrec

macro tailrec(func)
    fargs=map(e->if isa(e,Expr) e.args[1] else e end,func.args[1].args)
    fbody=func.args[2]
    fbody=rewrite(fbody,fargs)
    func.args[2]=Expr(:block,:(@label retry),fbody)
    esc(func)
end

function rewrite(expr,args,callflag=false)
    if !isa(expr,Expr)
        expr
    elseif expr.head == :call && expr.args[1] == args[1]
        if callflag
            @warn "Not tail recursive call is found."
            expr
        else
            newargs=Expr(:tuple)
            newargs.args=args[2:end]
            oldargs=Expr(:tuple)
            oldargs.args=expr.args[2:end]
            Expr(:block, Expr(:(=),newargs,oldargs), :(@goto retry) )
        end
    elseif expr.head == :block
        expr.args[end]=rewrite(expr.args[end],args, expr.head==:call || callflag)
        expr
    else
        expr.args = map(a->rewrite(a,args, expr.head==:call ||callflag),expr.args)
        expr
    end
end
end
