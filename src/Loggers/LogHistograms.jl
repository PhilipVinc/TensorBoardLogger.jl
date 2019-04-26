"""
    log_histogram(logger, name, (bins,weights); step)

Logs a histogram under the tag `name` on given `step`. The histogram must be
passed as a tuple holding the `N+1` bin edges and the height of the `N` bins.

You can also pass the raw data, and a binning algorithm from `StatsBase.jl` will
be used to bin the data.
"""
function log_histogram(logger::TBLogger, name::AbstractString, (bins,weights)::Tuple{AbstractVector, AbstractArray};
                       step=nothing)
    weights = vec(weights)
    summ    = SummaryCollection()
    push!(summ.value,  histogram_summary(name, bins, weights))
    write_event(logger.file, make_event(logger, summ, step=step))
end

"""
    log_histogram(logger, name, data::Vector; step)

Bins the values found in `data` and logs them as an histogram under the tag
`name`.
"""
function log_histogram(logger::TBLogger, name::AbstractString, data::AbstractArray;
                       step=nothing)
    data = vec(data)
    summ    = SummaryCollection()
    hvals = fit(Histogram, data)
    push!(summ.value, histogram_summary(name, collect(hvals.edges[1]), hvals.weights))
    write_event(logger.file, make_event(logger, summ, step=step))
end

"""
    log_vector(logger, name, data::Vector; step)

Logs the vector found in `data` as an histogram under the name `name`.
"""
function log_vector(logger::TBLogger, name::AbstractString, data::AbstractVector; step=nothing)
    summ    = SummaryCollection()
    push!(summ.value, histogram_summary(name, collect(0:length(data)),data))
    write_event(logger.file, make_event(logger, summ, step=step))
end

function histogram_summary(name::AbstractString, edges::AbstractVector{<:Number}, hist_vals::AbstractVector{<:Number})
    @assert length(edges) == length(hist_vals)+1

    hp = HistogramProto(min=minimum(edges), max=maximum(edges),
                        bucket_limit=Vector{Float64}(),
                        bucket=Vector{Float64}())
    for val=edges[2:end]
        push!(hp.bucket_limit, val)
    end
    for val=hist_vals
        push!(hp.bucket, val)
    end

    Summary_Value(tag=name, histo=hp)
end


## Logger Interface

# Define the type(s) that can be serialized to TensorBoard
preprocess(name,   val::AbstractVector{<:Real}, data) = push!(data, name=>val)
summary_impl(name, val::AbstractVector{<:Real}) = histogram_summary(name, collect(0:length(val)),val)

preprocess(name,   (bins,weights)::Tuple{AbstractVector,AbstractVector}, data) = push!(data, name=>(bins, weights))
summary_impl(name, (bins,weights)::Tuple{AbstractVector,AbstractVector}) = histogram_summary(name, bins, weights)

# Split complex numbers into real/complex pairs
preprocess(name, val::AbstractVector{<:Complex}, data) = push!(data, name*"/re"=>real.(val), name*"/im"=>imag.(val))
preprocess(name, val::AbstractArray, data) = push!(data, name=>vec(val))
