require 'web3'
require 'uri'
url = URI.parse('https://eviex.io/webhooks/tx')
w3 = Web3.new 'http://localhost:8545'
lastbn = w3.eth_blockNumber - 5
while true
  accounts = w3.eth_accounts[1..-1]
  bn = w3.eth_blockNumber - 5
  if bn > lastbn + 2
    bn =  lastbn + 1
    lastbn = bn
  elsif bn == lastbn + 1
    lastbn = bn
  elsif bn == lastbn
    sleep 5
    next
  end
  block = w3.eth_getBlockByNumber('0x' + bn.to_s(16))
  for tx in block["transactions"]
    if accounts.include? tx["to"]
      puts tx
      req = Net::HTTP::Post.new(url)
      req.basic_auth 'bas@eviex.io', 'EvimeriaArcadia2019'
      req.set_form_data 'type'=>'transaction', 'hash'=>tx["hash"], 'channel'=>'ether'
      resp = Net::HTTP.start(url.host, url.port, :use_ssl => true) {|http| http.request(req) }
      puts resp
      postData = Net::HTTP.post_form(URI.parse('https://eviex.io/webhooks/tx'), {'type'=>'transaction', 'hash'=>tx["hash"], 'channel'=>'ether'})
      sleep 1
    end
  end
  sleep 5
end

