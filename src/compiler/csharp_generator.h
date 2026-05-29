/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#ifndef GRPC_INTERNAL_COMPILER_CSHARP_GENERATOR_H
#define GRPC_INTERNAL_COMPILER_CSHARP_GENERATOR_H

#include "src/compiler/config.h"

namespace grpc_csharp_generator {

std::string GetServices(const grpc::protobuf::FileDescriptor* file,
                        bool generate_client, bool generate_server,
                        bool internal_access, bool append_async_suffix);

// TCP variant: emits an abstract `<Service>Base : IPacketHandler` whose RPC
// methods are synchronous `<Response> <Method>(<Request> request, Connection
// connection)` tagged with `[PacketHandler(MsgId.<Method>)]`. Routes over the
// TemplateTCPServer packet dispatcher instead of gRPC/HTTP-2. No client stub,
// no marshallers, no BindService, no ServerCallContext.
std::string GetServicesTcp(const grpc::protobuf::FileDescriptor* file,
                           bool internal_access);

}  // namespace grpc_csharp_generator

#endif  // GRPC_INTERNAL_COMPILER_CSHARP_GENERATOR_H
