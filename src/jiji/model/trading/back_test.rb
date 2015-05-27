# coding: utf-8

require 'jiji/configurations/mongoid_configuration'
require 'jiji/utils/value_object'
require 'thread'
require 'singleton'
require 'jiji/web/transport/transportable'

module Jiji::Model::Trading
  class BackTest

    include Encase
    include Mongoid::Document
    include Jiji::Utils::ValueObject
    include Jiji::Web::Transport::Transportable
    include Jiji::Errors
    include Jiji::Model::Trading

    needs :logger
    needs :time_source
    needs :back_test_thread_pool
    needs :tick_repository
    needs :securities_provider
    # needs :agents_factory

    store_in collection: 'backtests'

    field :name,          type: String
    field :created_at,    type: Time
    field :memo,          type: String

    field :start_time,    type: Time
    field :end_time,      type: Time
    field :agent_setting, type: Hash
    field :pairs,         type: Array

    validates :name,
      length:   { maximum: 200, strict: true },
      presence: { strict: true }

    validates :memo,
      length:      { maximum: 2000, strict: true },
      allow_nil:   true,
      allow_blank: true

    validates :created_at,
      presence: { strict: true }
    validates :start_time,
      presence: { strict: true }
    validates :end_time,
      presence: { strict: true }
    validates :pairs,
      presence: { strict: true },
      length:   { minimum: 1 }

    index(
      { created_at: 1, id: 1 },
      unique: true, name: 'backtests_created_at_id_index')

    attr_reader :process

    def to_h
      {
        id:         _id,
        name:       name,
        memo:       memo,
        pairs:      pairs,
        created_at: created_at,
        start_time: start_time,
        end_time:   end_time
      }
    end

    def self.create_from_hash(hash)
      BackTest.new do |b|
        b.name       = hash['name']
        b.memo       = hash['memo']
        b.pairs      = hash['pairs']
        b.start_time = hash['start_time']
        b.end_time   = hash['end_time']
      end
    end

    def setup
      self.created_at = time_source.now

      # @agents         = agents_factory.create(agent_setting)
      broker           = create_broker
      trading_context  = create_trading_context(broker)
      @process         = create_process(trading_context)

      @process.start
      @process.post_job(Jobs::NotifyNextTickJobForBackTest.new)
    end

    def delete
      # TODO: delete positions, logs
      super
    end

    private

    def create_broker
      Brokers::BackTestBroker.new(_id, start_time, end_time,
        pairs,  @tick_repository, @securities_provider)
    end

    def create_trading_context(broker)
      TradingContext.new(@agents, broker, time_source, @logger)
    end

    def create_process(trading_context)
      Process.new(trading_context, back_test_thread_pool, true)
    end

  end
end
