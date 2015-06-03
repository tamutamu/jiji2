# coding: utf-8

require 'jiji/test/test_configuration'
require 'jiji/test/data_builder'

describe Jiji::Model::Trading::Position do
  let(:position_builder) do
    Jiji::Model::Trading::Internal::PositionBuilder.new
  end

  before(:example) do
    @data_builder = Jiji::Test::DataBuilder.new
  end

  after(:example) do
    @data_builder.clean
  end

  it 'バックテスト向け設定でPositionを作成できる' do
    position = position_builder.build_from_tick(
      'test', nil, :EURJPY, 10_000, :buy, @data_builder.new_tick(1), {
        take_profit:     102,
        stop_loss:       100,
        trailing_stop:   5,
        trailing_amount: 10
    })
    position.save

    expect(position.back_test_id).to eq('test')
    expect(position.internal_id).to eq(nil)
    expect(position.pair_name).to eq(:EURJPY)
    expect(position.units).to eq(10_000)
    expect(position.sell_or_buy).to eq(:buy)
    expect(position.entry_price).to eq(101.003)
    expect(position.entered_at).to eq(Time.at(0))
    expect(position.current_price).to eq(101.00)
    expect(position.updated_at).to eq(Time.at(0))
    expect(position.exit_price).to eq(nil)
    expect(position.exited_at).to eq(nil)
    expect(position.status).to eq(:live)
    expect(position.closing_policy.take_profit).to eq(102)
    expect(position.closing_policy.stop_loss).to eq(100)
    expect(position.closing_policy.trailing_stop).to eq(5)
    expect(position.closing_policy.trailing_amount).to eq(10)

    expect(Jiji::Model::Trading::Position.count).to eq(1)

    position = position_builder.build_from_tick(
      'test', nil, :EURUSD, 20_000, :sell, @data_builder.new_tick(1))
    position.save

    expect(position.back_test_id).to eq('test')
    expect(position.internal_id).to eq(nil)
    expect(position.pair_name).to eq(:EURUSD)
    expect(position.units).to eq(20_000)
    expect(position.sell_or_buy).to eq(:sell)
    expect(position.entry_price).to eq(101.00)
    expect(position.entered_at).to eq(Time.at(0))
    expect(position.current_price).to eq(101.003)
    expect(position.updated_at).to eq(Time.at(0))
    expect(position.exit_price).to eq(nil)
    expect(position.exited_at).to eq(nil)
    expect(position.status).to eq(:live)
    expect(position.closing_policy.take_profit).to eq(0)
    expect(position.closing_policy.stop_loss).to eq(0)
    expect(position.closing_policy.trailing_stop).to eq(0)
    expect(position.closing_policy.trailing_amount).to eq(0)

    expect(Jiji::Model::Trading::Position.count).to eq(2)
  end

  it 'RMT向け設定でPositionを作成できる' do
    position = position_builder.build_from_tick(
      nil, '1', :EURUSD, 1_000_000, :sell, @data_builder.new_tick(2), {
        take_profit:     102,
        stop_loss:       100,
        trailing_stop:   5,
        trailing_amount: 10
    })
    position.save

    expect(position.back_test_id).to eq(nil)
    expect(position.internal_id).to eq('1')
    expect(position.pair_name).to eq(:EURUSD)
    expect(position.units).to eq(1_000_000)
    expect(position.sell_or_buy).to eq(:sell)
    expect(position.entry_price).to eq(102.0)
    expect(position.entered_at).to eq(Time.at(0))
    expect(position.current_price).to eq(102.003)
    expect(position.updated_at).to eq(Time.at(0))
    expect(position.exit_price).to eq(nil)
    expect(position.exited_at).to eq(nil)
    expect(position.status).to eq(:live)
    expect(position.closing_policy.take_profit).to eq(102)
    expect(position.closing_policy.stop_loss).to eq(100)
    expect(position.closing_policy.trailing_stop).to eq(5)
    expect(position.closing_policy.trailing_amount).to eq(10)

    expect(Jiji::Model::Trading::Position.count).to eq(1)
  end

  it 'update で現在価値を更新できる' do
    position = position_builder.build_from_tick(
      'test', nil, :EURUSD, 10_000, :buy, @data_builder.new_tick(1))

    expect(position.profit_or_loss).to eq(-30)

    position.update(@data_builder.new_tick(2, Time.at(100)))
    expect(position.entry_price).to eq(101.003)
    expect(position.current_price).to eq(102.00)
    expect(position.updated_at).to eq(Time.at(100))
    expect(position.profit_or_loss).to eq(9970)

    position.update(@data_builder.new_tick(3, Time.at(200)))
    expect(position.entry_price).to eq(101.003)
    expect(position.current_price).to eq(103.00)
    expect(position.updated_at).to eq(Time.at(200))
    expect(position.profit_or_loss).to eq(19_970)

    position = position_builder.build_from_tick(
      nil, 1, :EURUSD, 100_000, :sell, @data_builder.new_tick(1))

    expect(position.profit_or_loss).to eq(-300)

    position.update(@data_builder.new_tick(2, Time.at(100)))
    expect(position.entry_price).to eq(101.00)
    expect(position.current_price).to eq(102.003)
    expect(position.updated_at).to eq(Time.at(100))
    expect(position.profit_or_loss).to eq(-100_300)

    position.update(@data_builder.new_tick(3, Time.at(200)))
    expect(position.entry_price).to eq(101.00)
    expect(position.current_price).to eq(103.003)
    expect(position.updated_at).to eq(Time.at(200))
    expect(position.profit_or_loss).to eq(-200_300)

    position.update(@data_builder.new_tick(0, Time.at(100)))
    expect(position.entry_price).to eq(101.00)
    expect(position.current_price).to eq(100.003)
    expect(position.updated_at).to eq(Time.at(100))
    expect(position.profit_or_loss).to eq(99_700)
  end

  it 'close で約定済み状態にできる' do
    position = position_builder.build_from_tick(
      nil, '1', :EURUSD, 10_000, :buy, @data_builder.new_tick(1))

    position.close
    expect(position.back_test_id).to eq(nil)
    expect(position.internal_id).to eq('1')
    expect(position.pair_name).to eq(:EURUSD)
    expect(position.units).to eq(10_000)
    expect(position.sell_or_buy).to eq(:buy)
    expect(position.entry_price).to eq(101.003)
    expect(position.entered_at).to eq(Time.at(0))
    expect(position.current_price).to eq(101.0)
    expect(position.updated_at).to eq(Time.at(0))
    expect(position.exit_price).to eq(101.0)
    expect(position.exited_at).to eq(Time.at(0))
    expect(position.status).to eq(:closed)

    position = position_builder.build_from_tick(
      'test', nil, :EURUSD, 10_000, :sell, @data_builder.new_tick(1))

    position.update(@data_builder.new_tick(2, Time.at(100)))

    position.close
    expect(position.back_test_id).to eq('test')
    expect(position.internal_id).to eq(nil)
    expect(position.pair_name).to eq(:EURUSD)
    expect(position.units).to eq(10_000)
    expect(position.sell_or_buy).to eq(:sell)
    expect(position.entry_price).to eq(101.0)
    expect(position.entered_at).to eq(Time.at(0))
    expect(position.current_price).to eq(102.003)
    expect(position.updated_at).to eq(Time.at(100))
    expect(position.exit_price).to eq(102.003)
    expect(position.exited_at).to eq(Time.at(100))
    expect(position.status).to eq(:closed)
  end

  it 'to_hでハッシュに変換できる' do
    position = position_builder.build_from_tick(
      nil, '1', :EURUSD, 1_000_000, :sell, @data_builder.new_tick(2), {
        take_profit:     102,
        stop_loss:       100,
        trailing_stop:   5,
        trailing_amount: 10
    })

    hash = position.to_h

    expect(hash[:back_test_id]).to eq(nil)
    expect(hash[:internal_id]).to eq('1')
    expect(hash[:pair_name]).to eq(:EURUSD)
    expect(hash[:units]).to eq(1_000_000)
    expect(hash[:sell_or_buy]).to eq(:sell)
    expect(hash[:entry_price]).to eq(102.0)
    expect(hash[:entered_at]).to eq(Time.at(0))
    expect(hash[:current_price]).to eq(102.003)
    expect(hash[:updated_at]).to eq(Time.at(0))
    expect(hash[:exit_price]).to eq(nil)
    expect(hash[:exited_at]).to eq(nil)
    expect(hash[:status]).to eq(:live)
    expect(hash[:closing_policy][:take_profit]).to eq(102)
    expect(hash[:closing_policy][:stop_loss]).to eq(100)
    expect(hash[:closing_policy][:trailing_stop]).to eq(5)
    expect(hash[:closing_policy][:trailing_amount]).to eq(10)
  end
end
