#=
Operations on TS objects
=#

import Base: ones, zeros, trues, falses, sum, mean, maximum, minimum, prod, cumsum, cumprod, diff
importall Base.Operators


ones(x::TS) = ts(ones(x.values), x.index, x.fields)
zeros(x::TS) = ts(zeros(x.values), x.index, x.fields)
trues(x::TS) = ts(trues(x.values), x.index, x.fields)
falses(x::TS) = ts(falses(x.values), x.index, x.fields)

# Function to pass Array operators through to underlying TS values
function op{V,T}(x::TS{V,T}, y::TS{V,T}, fun::Function; args...)
    idx = intersect(x.index, y.index)
    return ts(fun(x[idx].values, y[idx].values; args...), idx, x.fields)
end

# Number functions
sum(x::TS) = sum(x.values)
sum(x::TS, dim::Int) = sum(x.values, dim)
sum(f::Function, x::TS) = sum(f, x.values)
mean(x::TS) = mean(x.values)
mean(x::TS, dim::Int) = mean(x, dim)
prod(x::TS) = prod(x.values)
prod(x::TS, dim::Int) = prod(x.values, dim)
maximum(x::TS) = maximum(x.values)
maximum(x::TS, dim::Int) = maximum(x.values, dim)
minimum(x::TS) = minimum(x.values)
minimum(x::TS, dim::Int) = minimum(x.values, dim)
cumsum(x::TS, dim::Int=1) = ts(cumsum(x.values, dim), x.index, x.fields)
cummin(x::TS, dim::Int=1) = ts(cummin(x.values, dim), x.index, x.fields)
cummax(x::TS, dim::Int=1) = ts(cummax(x.values, dim), x.index, x.fields)
cumprod(x::TS, dim::Int=1) = ts(cumprod(x.values, dim), x.index, x.fields)

nans(r::Int, c::Int) = fill(NaN, 1, 2)
nans(dims::Tuple{Int,Int}) = fill(NaN, dims)
function rowdx!{T,N}(dx::AbstractArray{T,N}, x::AbstractArray{T,N}, n::Int, r::Int=size(x,1))
    idx = n > 0 ? (n+1:r) : (1:r+n)
    @inbounds for i=idx
        dx[i,:] = x[i,:] - x[i-n,:]
    end
    nothing
end
function coldx!{T,N}(dx::AbstractArray{T,N}, x::AbstractArray{T,N}, n::Int, c::Int=size(x,2))
    idx = n > 0 ? (n+1:c) : (1:c+n)
    @inbounds for j=idx
        dx[:,j] = x[:,j] - x[:,j-n]
    end
    nothing
end
function diffn{T<:Number,N}(x::Array{T,N}, dim::Int=1, n::Int=1)
    @assert dim == 1 || dim == 2 "Argument `dim` must be 1 (rows) or 2 (columns)."
    @assert abs(n) < size(x,dim) "Argument `n` out of bounds."
    if n == 0
        return x
    end
    dx = zeros(x)
    if dim == 1
        rowdx!(dx, x, n)
    else
        coldx!(dx, x, n)
    end
    return dx
end
function diff{V,T}(x::TS{V,T}; dim::Int=1, n::Int=1, pad::Bool=true, padval::V=zero(V))
    r, c = size(x)
    dx = diffn(x.values, dim, n)
    if dim == 1
        if pad
            idx = n>0 ? (1:n) : (r+n+1:r)
            dx[idx,:] = padval
            return ts(dx, x.index, x.fields)
        else
            idx = n > 0 ? (n+1:r) : (1:r+n)
            return ts(dx[idx,:], x.index[idx], x.fields)
        end
    else
        if pad
            idx = n > 0 ? (1:c) : (c+1+1:c)
            dx[:,idx] = padval
            return ts(dx, x.index, x.fields[idx])
        else
            idx = n > 0 ? (n+1:c) : (1:c+n)
            return ts(dx[:,idx], x.index, x.fields[idx])
        end
    end
end
function lag{V,T}(x::TS{V,T}, n::Int=1; pad::Bool=true, padval::V=zero(V))
	@assert abs(n) < size(x,1) "Argument `n` out of bounds."
	if n == 0
		return x
	elseif n > 0
		out = zeros(x.values)
		out[n+1:end,:] = x.values[1:end-n,:]
	elseif n < 0
		out = zeros(x.values)
		out[1:end+n,:] = x.values[1-n:end,:]
	end
    r, c = size(x)
    if pad
        idx = n>0 ? (1:n) : (r+n+1:r)
        out[idx,:] = padval
        return ts(out, x.index, x.fields)
    else
        idx = n > 0 ? (n+1:r) : (1:r+n)
        return ts(out[idx,:], x.index[idx], x.fields)
    end
end

# Artithmetic operators
+(x::TS) = ts(+x.values, x.index, x.fields)
-(x::TS) = ts(-x.values, x.index, x.fields)
+(x::TS, y::TS) = op(x, y, +)
-(x::TS, y::TS) = op(x, y, -)
*(x::TS, y::TS) = op(x, y, *)
/(x::TS, y::TS) = op(x, y, /)
.+(x::TS, y::TS) = op(x, y, .+)
.-(x::TS, y::TS) = op(x, y, .-)
.*(x::TS, y::TS) = op(x, y, .*)
./(x::TS, y::TS) = op(x, y, ./)
.\(x::TS, y::TS) = op(x, y, .\)
.^(x::TS, y::TS) = op(x, y, .^)
.%(x::TS, y::TS) = op(x, y, .%)

+(x::TS, y::AbstractArray) = ts(x.values + y, x.index, x.fields)
-(x::TS, y::AbstractArray) = ts(x.values - y, x.index, x.fields)
*(x::TS, y::AbstractArray) = ts(x.values * y, x.index, x.fields)
/(x::TS, y::AbstractArray) = ts(x.values / y, x.index, x.fields)
.+(x::TS, y::AbstractArray) = ts(x.values .+ y, x.index, x.fields)
.-(x::TS, y::AbstractArray) = ts(x.values .- y, x.index, x.fields)
.*(x::TS, y::AbstractArray) = ts(x.values .* y, x.index, x.fields)
./(x::TS, y::AbstractArray) = ts(x.values ./ y, x.index, x.fields)
.\(x::TS, y::AbstractArray) = ts(x.values .\ y, x.index, x.fields)
.^(x::TS, y::AbstractArray) = ts(x.values .^ y, x.index, x.fields)
.%(x::TS, y::AbstractArray) = ts(x.values .% y, x.index, x.fields)

+(x::TS, y::Number) = ts(x.values + y, x.index, x.fields)
+(x::TS, y::Number) = ts(x.values + y, x.index, x.fields)
-(x::TS, y::Number) = ts(x.values - y, x.index, x.fields)
*(x::TS, y::Number) = ts(x.values * y, x.index, x.fields)
/(x::TS, y::Number) = ts(x.values / y, x.index, x.fields)
.+(x::TS, y::Number) = ts(x.values .+ y, x.index, x.fields)
.-(x::TS, y::Number) = ts(x.values .- y, x.index, x.fields)
.*(x::TS, y::Number) = ts(x.values .* y, x.index, x.fields)
./(x::TS, y::Number) = ts(x.values ./ y, x.index, x.fields)
.\(x::TS, y::Number) = ts(x.values .\ y, x.index, x.fields)
.^(x::TS, y::Number) = ts(x.values .^ y, x.index, x.fields)
.%(x::TS, y::Number) = ts(x.values .% y, x.index, x.fields)

+(y::AbstractArray, x::TS) = x + y
+(y::Number, x::TS) = x + y
