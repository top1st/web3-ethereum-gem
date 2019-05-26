require 'bigdecimal/util'
require 'web3'
class Geth_Client

  def initialize(rpc_url='http://localhost:8545', attributes={})
    @client = Web3.new(rpc_url)
  end

  def client
    @client ||= Web3.new(rpc_url)
  end

  def create_erc20_transaction(contract_address, from, secret, to, amount)
    if @client.personal_unlockAccount(from, secret, 5000)
      data = abi_encode \
        'transfer(address,uint256)',
        normalize_address(to),
        '0x' + amount_to_base_unit(amount, token_decimals(contract_address)).to_i.to_s(16)

      transobj = {
          from:     normalize_address(from),
          to:       contract_address,
          data:     data,
          gas:      '0x' + 300_000.to_i.to_s(16),
          gasPrice: '0x' + 3_000_000_000.to_i.to_s(16)
      }

      # max fee 0.0009 ether
      p @client.eth_sendTransaction(transobj)
    else
      p 'unlock account error'
    end
  end

  def inspect_erc20_transaction(txid)
    @client.eth_getTransactionByHash(txid)
  end

  def token_decimals(contract_address)
    data = abi_encode('decimals()')
    @client.eth_call({to: contract_address, data: data}).to_i(16)
  end

  protected

  def abi_encode(method, *args)
    '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
      data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
    end
  end

  def abi_explode(data)
    data = data.gsub(/\A0x/, '')
    { method:    '0x' + data[0...8],
      arguments: data[8..-1].chars.in_groups_of(64, false).map { |group| '0x' + group.join } }
  end

  def normalize_address(address)
    address.downcase
  end

  def amount_to_base_unit(amount, decimal=18)
    amount.to_d * 10**decimal
  end

end