# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: logging.proto for package 'jiji.rpc'

require 'grpc'
require 'logging_pb'

module Jiji
  module Rpc
    module LoggerService
      class Service

        include GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'jiji.rpc.LoggerService'

        rpc :log, LoggingRequest, Google::Protobuf::Empty
      end

      Stub = Service.rpc_stub_class
    end
  end
end
