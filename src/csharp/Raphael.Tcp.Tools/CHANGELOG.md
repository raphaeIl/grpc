# Changelog

All notable changes to **Raphael.Tcp.Tools** are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this package uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0]

### Added
- New TCP codegen option `msgid_prefix` (MSBuild property: `TcpMsgIdPrefix`) controls
  the prefix used when constructing `MsgId` enum member names. Default is `Msg`.

### Changed
- **Breaking (generated API shape):** TCP handlers are now generated as top-level
  classes; the outer static wrapper service class is no longer emitted.
- **Breaking (generated API shape):** TCP base class naming changed from
  `<ServiceName>Base` to `<ServiceNameWithoutService>HandlerBase`
  (for example, `GunServiceBase` -> `GunHandlerBase`).
- **Breaking (MsgId mapping):** request/reply `MsgId` values are now derived from
  request/response message type names instead of rpc names.
  - `CS_*` and `SC_*` message prefixes are normalized to `Cs` and `Sc`.
  - The configured `msgid_prefix` is prepended.
  - `Reply`/`Response` suffix trimming is no longer applied.

## [1.1.2]

### Fixed
- TCP base codegen now passes protobuf's well-known-types include dir
  (`Protobuf_StandardImportsPath`) to its `protoc` invocation. Previously the
  hand-rolled `Exec` passed only `--proto_path=$(TcpProtoDir)`, so any TCP proto
  that imported `google/protobuf/*.proto` failed to generate. This broke the
  `google.protobuf.Empty` -> `void` feature (added in 1.1.0), which requires
  importing `google/protobuf/empty.proto`.

## [1.1.1]

### Added
- This changelog and `PackageReleaseNotes` so version history is visible on the NuGet page.

## [1.1.0]

### Added
- `google.protobuf.Empty` response maps to a C# `void` TCP handler. An Empty-returning
  rpc is the explicit "no canonical auto-reply" signal: the generated handler returns
  `void` and no `ReplyMsgId` is baked into the `[PacketHandler(...)]` attribute, so the
  dispatcher sends nothing automatically and the handler pushes any packets itself via
  the `Connection`.

### Changed
- **Breaking (build properties):** dropped the `Raphael` prefix from all MSBuild
  properties — `RaphaelTcpIPacketHandler` → `TcpIPacketHandler`,
  `RaphaelTcpPacketHandlerAttr` → `TcpPacketHandlerAttr`,
  `RaphaelTcpConnection` → `TcpConnection`, `RaphaelTcpProtoDir` → `TcpProtoDir`,
  `RaphaelTcpOutDir` → `TcpOutDir`, `RaphaelTcpPluginExe` → `TcpPluginExe`.
  Consuming projects must rename these in their csproj. The package id stays
  `Raphael.Tcp.Tools`.

## [1.0.0]

### Added
- Initial release: forked `grpc_csharp_plugin` (TCP packet-handler variant) plus MSBuild
  props/targets that generate synchronous TCP service bases from `.proto` files.
  Windows-x64 only.
