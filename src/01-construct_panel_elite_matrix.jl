using CSV
using Dates
using DataFrames
using DelimitedFiles
using LoggingExtras
using MatrixMarket: mmread, mmwrite
using NamedArrays
using Pipe
using SparseArrays

const date_format = "yyyy-mm-dd HH:MM:SS"

timestamp_logger(logger) = TransformerLogger(logger) do log
  merge(log, (; message = "$(Dates.format(now(), date_format)) $(log.message)"))
end

ConsoleLogger(stdout, Logging.Debug) |> timestamp_logger |> global_logger

function stem_dirpath(dirpath::String)
    dirpath = rstrip(dirpath, '/')
    stem = split(dirpath, '/')[end]
    return stem
end

function load_follow_mat(dirpath::String)
    stem = stem_dirpath(dirpath)

    @debug "beginning mmread"
    mat = NamedArray(mmread("$(dirpath)/$(stem)_mat.mtx"))
    @debug "finish mmread"

    setnames!(mat, readlines("$(dirpath)/$(stem)_mat_rownames.txt"), 1)
    @debug "set rownames"

    setnames!(mat, readlines("$(dirpath)/$(stem)_mat_colnames.txt"), 2)
    @debug "set colnames"

    return mat
end

function build_panel_elite_matrix(mat::NamedArray, elites::DataFrame, target_col::Symbol)
    # if !("meta_id" in names(elites))
    #     elites = @pipe elites |>
    #         transform(_, :user_id => eachindex => :_r) |>
    #         transform(_, :_r => ByRow(x-> "meta_$(x)") => :meta_id) |>
    #         select(_, Not(:_r))
    # end

    @debug "filtering elites df"
    elites = @pipe elites |>
        subset(_, :user_id => ByRow(in(names(mat, 2)))) |>
        groupby(_, target_col) |>
        transform(_, :user_id => eachindex => :rank)
    max_rank = maximum(elites.rank)

    @debug "initializing new matrix"
    new_mat = NamedArray(spzeros(length(names(mat, 1)), length(unique(elites[!, target_col]))))
    setnames!(new_mat, string.(names(mat, 1)), 1)
    setnames!(new_mat, string.(unique(elites[!, target_col])), 2)
    @debug("initialized new matrix")

    @debug "setting base values"
    r = 1
    elites_of_common_rank = subset(elites, :rank => ByRow(==(r)))
    identity_mapper = NamedArray(elites_of_common_rank[!, target_col])
    setnames!(identity_mapper, elites_of_common_rank[!, :user_id], 1)
    new_mat[:, string.(identity_mapper)] = mat[:, string.(names(identity_mapper, 1))]

    @debug("set base values")
    # TODO: warning about dropping mismatching names
    if (max_rank > 1)
        for r in 2:max_rank
            @debug "applying rank $r"
            elites_of_common_rank = subset(elites, :rank => ByRow(==(r)))
            identity_mapper = NamedArray(elites_of_common_rank[!, target_col])
            setnames!(identity_mapper, elites_of_common_rank[!, :user_id], 1)
            new_mat[:, string.(identity_mapper)] = new_mat[:, string.(identity_mapper)] + mat[:, string.(names(identity_mapper, 1))]
        end
    end

    @debug "binarizing matrix"
    new_mat = sign.(new_mat)

    return new_mat
end


function pair_follow_crawl_and_elites_file(
    follow_dirpath::String,
    elites_file::String,
    output_dir::String,
    target_col::Symbol,
    )
    @info "creating matrix for crawl $(follow_dirpath) and elites file $(elites_file)"
    @debug "loading matrix"
    mat = load_follow_mat(follow_dirpath)
    @debug "loaded matrix"

    elites = CSV.read(elites_file, DataFrame, types=Dict(:user_id => String))
    @debug "loaded elites"

    new_mat = build_panel_elite_matrix(mat, elites, target_col)
    @debug "built matrix"

    mkpath(output_dir)
    stem = stem_dirpath(output_dir)
    mmwrite("$(output_dir)/$(stem)_mat.mtx", new_mat.array)
    writedlm("$(output_dir)/$(stem)_mat_rownames.txt", names(new_mat, 1))
    writedlm("$(output_dir)/$(stem)_mat_colnames.txt", names(new_mat, 2))
    @debug "wrote matrix"
end


function main()
    sep2020crawl = "/net/data-backedup/twitter-voters/friends_collect/full_follow_matrices/friends_sep2020"
    elites_v2 = "../data/elites_combined_v2.tsv"

    jan2018crawl = "/net/data-backedup/twitter-voters/friends_collect/full_follow_matrices/friends_jan2018"
    barbera_pa = "../data/barbera_pa_elites.tsv"
    barbera_ps = "../data/barbera_ps_elites.tsv"

    #pair_follow_crawl_and_elites_file(jan2018crawl, elites_v2, "../data/matrices/elites_v2_jan2018/", :meta_id)
    #pair_follow_crawl_and_elites_file(sep2020crawl, elites_v2, "../data/matrices/elites_v2_sep2020/", :meta_id)
    pair_follow_crawl_and_elites_file(jan2018crawl, barbera_ps, "../data/matrices/barbera_elites_ps_jan2018/", :screen_name)
    pair_follow_crawl_and_elites_file(jan2018crawl, barbera_pa, "../data/matrices/barbera_elites_pa_jan2018/", :screen_name)
    pair_follow_crawl_and_elites_file(sep2020crawl, barbera_ps, "../data/matrices/barbera_elites_ps_sep2020/", :screen_name)
    pair_follow_crawl_and_elites_file(sep2020crawl, barbera_pa, "../data/matrices/barbera_elites_pa_sep2020/", :screen_name)
end

main()
