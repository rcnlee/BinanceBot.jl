module BinanceBot

using Binance, CoinMarketCap, DataFrames, CSV

export write_symbol_map, read_symbol_map, write_market_cap_list, read_market_cap_list, 
    write_price_data, read_price_data, sorted_roundtrip

function write_symbol_map(file::AbstractString="symbolmap.csv", client=Client())
    df = get_symbol_map(DataFrame, client)
    CSV.write(file, df)
    df
end
function read_symbol_map(file::AbstractString="symbolmap.csv")
    get_symbol_map(Dict, nothing, CSV.read(file))  #Dict{String, Tuple{String,String}}
end
function write_market_cap_list(file::AbstractString="marketcaplist.csv",
                               market=Market(); 
                               thresh::Float64=0.5e9)
    df = ticker_by_cap(DataFrame, market, thresh)
    CSV.write(file, df[[:symbol]])
end
function read_market_cap_list(file::AbstractString="marketcaplist.csv")
    d = CSV.read(file)
    convert(Vector, d[:symbol])  #Vector{String}
end
function write_price_data(file::AbstractString="prices.csv", client=Client())
    df = get_all_tickers(DataFrame, client)
    CSV.write(file, df)
end
function read_price_data(file::AbstractString="prices.csv")
    get_all_tickers(Dict, nothing, CSV.read(file))
end

function sorted_roundtrip(client, sym_list::Vector{String}, 
                          prices::Dict{String,Float64}=get_all_tickers(Dict, client), 
                          base_syms::Vector{String}=base_symbols(), 
                          derived_syms::Vector{String}=setdiff(sym_list,base_symbols());
                          cost_per_trade::Float64=0.001)
    slip = 1.0 - cost_per_trade
    v = []
    for b1 in base_syms, d in derived_syms, b2 in base_syms
        if b1 != b2
            if !haskey(prices, "$d$b1") || !haskey(prices, "$d$b2")  
                continue
            end
            if  !haskey(prices, "$b1$b2") && !haskey(prices, "$b2$b1")
                continue
            end
            p1 = prices["$d$b1"] * slip
            p2 = 1 / prices["$d$b2"] * slip
            if haskey(prices, "$b1$b2")
                p3 = prices["$b1$b2"] * slip
            elseif haskey(prices, "$b2$b1")
                p3 = 1 / prices["$b2$b1"] * slip
            else
                error("shouldn't have gotten here... $b2$b1")
            end
            p = p1 * p2 * p3
            push!(v, (b1, d, b2, p1, p2, p3, p))
        end
    end
    sort!(v, by=x->x[7], rev=true)
end

end # module
