# kubernetes-cookbook

Application cookbook for Kubernetes Cluster installation and configuration

## Supported Platforms

Centos 7.x

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['docker']['version']</tt></td>
    <td>String</td>
    <td>Docker engine version</td>
    <td><tt>1.12.1</tt></td>
  </tr>
  <tr>
    <td><tt>['docker']['storage_driver']</tt></td>
    <td>String</td>
    <td>Docker engine storage driver</td>
    <td><tt>overlay</tt></td>
  </tr>
</table>

## Usage

Placeholder. TBD.

### kubernetes::default

Include `kubernetes` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[kubernetes::default]"
  ]
}
```

## License and Authors

Author:: Alex Litvinenko (<altvnk@me.com>)
