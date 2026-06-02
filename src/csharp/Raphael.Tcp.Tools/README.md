# Raphael.Tcp.Tools

Self-contained protoc build-time tooling that generates **synchronous TCP
packet-handler service bases** — plus the C# message classes — from your
`.proto` files, instead of gRPC's HTTP/2 async stubs.

It ships its own `protoc`, a forked `grpc_csharp_plugin` (gRPC's C# code
generator, modified) and the well-known-type proto includes, so a `service` in a
`.proto` becomes a top-level abstract handler base you implement on a raw TCP
packet server — no HTTP/2, no `ServerCallContext`, no async `Task<T>`, and **no
`Grpc.Tools` dependency**.

For each unary `rpc Ping (PingRequest) returns (PongReply)` it emits:

```csharp
public abstract partial class GunHandlerBase : global::MyApp.Net.IPacketHandler
{
    [PacketHandler(MsgId.PingRequest, MsgId.PongReply)]
    public virtual PongReply Ping(PingRequest request, Connection connection)
        => throw new NotImplementedException("Ping is not implemented.");
}
```

- no static wrapper service class is generated;
- handler class name is `<ServiceNameWithoutService>HandlerBase`
  (for example, `GunService` -> `GunHandlerBase`);
- the method is **synchronous** (returns the response, not `Task<T>`);
- it receives your `Connection` instead of gRPC's `ServerCallContext`;
- a `google.protobuf.Empty` response maps to a `void` handler with no
  `ReplyMsgId` (the explicit "no canonical auto-reply" signal — the handler
  pushes any packets itself via the `Connection`).

## Zero-config default

With **no** MSBuild properties set, the generator assumes everything lives in the
proto's own `csharp_namespace`:

- handler/attribute/connection types default to
  `<csharp_namespace>.IPacketHandler`, `<csharp_namespace>.PacketHandlerAttribute`,
  `<csharp_namespace>.Connection`;
- `MsgId` members are the **exact** message type names — `PingRequest`,
  `PongReply`, etc. (no prefix, no `CS_`/`SC_` rewriting);
- the `MsgId` enum itself is `<csharp_namespace>.MsgId`;
- generated files land in the `obj/` root.

```xml
<ItemGroup>
  <PackageReference Include="Raphael.Tcp.Tools" Version="2.0.0" />
  <PackageReference Include="Google.Protobuf" Version="3.27.0" /> <!-- runtime for the messages -->
  <Protobuf Include="protos\**\*.proto" />
</ItemGroup>
```

Your project must define the four referenced types (`IPacketHandler`,
`PacketHandlerAttribute`, `Connection`, and a `MsgId` enum whose members match
the generated names) in the proto's `csharp_namespace`.

## Customization

Everything above is overridable from the consuming project's `PropertyGroup`.
Every property is optional — set only what you need. The block below shows the
**complete** set of configurable properties:

```xml
<PropertyGroup>
  <!-- ===== Generated type names ===== -->
  <!-- Fully-qualified names of YOUR types (no global:: prefix).
       Omit any one to default it to <csharp_namespace>.<ShortName>. -->
  <TcpIPacketHandler>Custom.Server.IPacketHandler</TcpIPacketHandler>
  <TcpPacketHandlerAttr>Custom.Server.PacketHandlerAttribute</TcpPacketHandlerAttr>
  <TcpConnection>Custom.Server.Connection</TcpConnection>

  <!-- FQN of the MsgId enum type. Default is <csharp_namespace>.MsgId. -->
  <TcpMsgId>Custom.Server.PacketTypes</TcpMsgId>

  <!-- ===== MsgId member naming ===== -->
  <!-- Prepended verbatim to the exact message name: PingRequest -> MsgPingRequest.
       Default is empty (exact message names). -->
  <TcpMsgIdPrefix>Msg</TcpMsgIdPrefix>

  <!-- Opt in to rewriting a leading CS_/SC_ to Cs/Sc before the prefix:
       CS_Login -> MsgCsLogin, SC_Login -> MsgScLogin. Default is false. -->
  <TcpNormalizeCsScPrefix>true</TcpNormalizeCsScPrefix>

  <!-- ===== Input / output ===== -->
  <!-- Output dir for BOTH the message file and the *Tcp.cs. Default: obj/ root. -->
  <TcpOutDir>Generated</TcpOutDir>

  <!-- Escape hatch: glob this directory for .proto files instead of using the
       <Protobuf Include=...> items. Leave unset to use <Protobuf> items. -->
  <TcpProtoDir>$(MSBuildProjectDirectory)\protos</TcpProtoDir>

  <!-- ===== Tool overrides (rarely needed) ===== -->
  <!-- Override the bundled windows_x64 binaries, e.g. to supply your own
       per-platform build. Defaults point at the binaries shipped in the package. -->
  <TcpProtocExe>$(MyTools)\protoc.exe</TcpProtocExe>
  <TcpPluginExe>$(MyTools)\grpc_csharp_plugin.exe</TcpPluginExe>
</PropertyGroup>
```

| Property | Default | Effect |
| --- | --- | --- |
| `TcpIPacketHandler` | `<csharp_namespace>.IPacketHandler` | FQN of the interface the generated base implements |
| `TcpPacketHandlerAttr` | `<csharp_namespace>.PacketHandlerAttribute` | FQN of the `[PacketHandler]` attribute |
| `TcpConnection` | `<csharp_namespace>.Connection` | FQN of the per-call connection type |
| `TcpMsgId` | `<csharp_namespace>.MsgId` | FQN of the `MsgId` enum type used in the attributes |
| `TcpMsgIdPrefix` | *(empty)* | String prepended to the exact message name for each `MsgId` member (`PingRequest` → `<prefix>PingRequest`) |
| `TcpNormalizeCsScPrefix` | `false` | When `true`, rewrite a leading `CS_`/`SC_` to `Cs`/`Sc` before applying `TcpMsgIdPrefix` |
| `TcpOutDir` | `$(IntermediateOutputPath)` (obj/ root) | Output dir for **both** the message file and the `*Tcp.cs` |
| `TcpProtoDir` | *(unset)* | Escape hatch: glob this directory for protos instead of using `<Protobuf>` items |
| `TcpProtocExe` | bundled `windows_x64\protoc.exe` | Override the `protoc` binary used for codegen |
| `TcpPluginExe` | bundled `windows_x64\grpc_csharp_plugin.exe` | Override the TCP plugin binary used for codegen |

Inputs are read from your `<Protobuf Include="..." />` items by default. Generated
files are compiled automatically, regenerated on build, and need not be committed.

## Platform support

**Windows-x64 only** in this version. On other platforms the build fails with a
clear error. To use it elsewhere, build `protoc` and the forked plugin for your
platform and set `TcpProtocExe` / `TcpPluginExe`.

## Requirements

- A `[PacketHandler]` attribute whose constructor accepts `(MsgId request)` and
  `(MsgId request, MsgId reply)`.
- `MsgId` enum members matching the generated names:
  - default: the exact message type name;
  - with `TcpMsgIdPrefix`: `<prefix><MessageName>`;
  - with `TcpNormalizeCsScPrefix`: a leading `CS_`/`SC_` becomes `Cs`/`Sc`.
- Streaming rpcs are skipped (unary only).

## License

Apache-2.0 (this is a fork of [grpc/grpc](https://github.com/grpc/grpc)).
