# Third-party notices

The generated ZimaOS package redistributes artifacts from these projects:

| Project | Version | License | Source |
| --- | --- | --- | --- |
| Mihomo | `v1.19.30` | MIT | `MetaCubeX/mihomo` |
| MetaCubeXD Server/Agent | `v1.273.0` | MIT | `MetaCubeX/metacubexd` |
| Node.js | `v22.23.2` | MIT and bundled third-party licenses | `nodejs/node` |

The build copies the upstream Mihomo and MetaCubeXD license texts into `/usr/share/licenses/mihomo-zimaos/` inside the `.raw` package. Node.js license information is copied from the official Node.js distribution.

This repository contains only ZimaOS packaging and integration files. It does not vendor the upstream source trees.
