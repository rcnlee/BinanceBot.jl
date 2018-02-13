
using BinanceBot, Binance

client = Client()
cap_list = read_market_cap_list("cap100m.csv")
prices = read_price_data("prices.csv")
v = sorted_roundtrip(client, cap_list, prices)

#implement
#* trades
#* depth analysis
#* streaming 

