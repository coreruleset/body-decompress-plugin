# OWASP ModSecurity Core Rule Set - Body Decompress Plugin

## Description

This is a plugin that brings on-the-fly decompression of `RESPONSE_BODY` to CRS
while running ModSecurity in embedded mode (please see ModSecurity configuration
directive `SecDisableBackendCompression` if you are running in reverse proxy
mode).

As some of the malicious software is using compression of response body to
bypass detection by checking the `RESPONSE_BODY` for patterns, this plugin will
help you to prevent this.

Decompression is performed using a bundled Lua script when:
 * response has `Content-Encoding` header which contains any of `gzip`, `compress`, `deflate`
 * `RESPONSE_BODY` starts with gzip magic number

Decompressed response body is then available via variable `TX:RESPONSE_BODY_DECOMPRESSED`.

Currently, only gzip decompression is supported.

## Prerequisities

 * CRS version 3.4 or newer (or see "Preparation for older installations" below)
 * ModSecurity compiled with Lua support
 * lua-zlib library

## lua-zlib library installation

lua-zlib library should be part of your linux distribution. Here is an example
of installation on Debian linux:  
`apt install lua-zlib`

## Plugin installation

Copy all files from `plugins` directory into the `plugins` directory of your
OWASP ModSecurity Core Rule Set (CRS) installation.

### Preparation for older installations

* Create a folder named `plugins` in your existing CRS installation. That folder
  is meant to be on the same level as the `rules` folder. So there is your
  `crs-setup.conf` file and next to it the two folders `rules` and `plugins`.
* Update your CRS rules include to follow this pattern:

```
<IfModule security2_module>

 Include modsecurity.d/owasp-modsecurity-crs/crs-setup.conf

 Include modsecurity.d/owasp-modsecurity-crs/plugins/*-config.conf
 Include modsecurity.d/owasp-modsecurity-crs/plugins/*-before.conf
 Include modsecurity.d/owasp-modsecurity-crs/rules/*.conf
 Include modsecurity.d/owasp-modsecurity-crs/plugins/*-after.conf

</IfModule>
```

_Your exact config may look a bit different, namely the paths. The important
part is to accompany the rules-include with two plugins-includes before and
after like above. Adjust the paths accordingly._

## Configuration

All settings can be done in file `plugins/body-decompress-config.conf` which
must be created by copying or renamig file `plugins/body-decompress-config.conf.example`:
`cp plugins/body-decompress-config.conf.example plugins/body-decompress-config.conf`

### tx.body-decompress-plugin_max_data_size_bytes

Maximum data size, in bytes, which are decompressed. If (compressed) data are
bigger, decompression is skipped. This option is available to lower chances of
successfull decompression bomb attack. Do NOT set this too high as decompression
is done inside RAM.

Default value: 102400

## Testing

After configuration, decompression should be tested. Here is an example rule and
PHP script which will produce compressed output. If decompression works ok,
request to the script will be blocked.

```
<?php
ini_set("zlib.output_compression", "On");
echo "22d51ee0c812123c541f2a1bdf794fd1";
?>
```

```
SecRule TX:RESPONSE_BODY_DECOMPRESSED "@contains 22d51ee0c812123c541f2a1bdf794fd1" \
    "id:99999,\
    phase:4,\
    block,\
    t:none,\
    msg:'RESPONSE_BODY decompression was successfull.',\
    severity:'CRITICAL',\
    setvar:'tx.outbound_anomaly_score_pl1=+%{tx.tx.critical_anomaly_score}',\
    setvar:'tx.anomaly_score_pl1=+%{tx.tx.critical_anomaly_score}'"
```

## Known problems

 * Web browsers are printing `Content Encoding Error` while blocking request
   which uses compression, as `Content-Encoding` header is still set and browser
   awaits compressed response. This problem is only affecting PHP applications
   if PHP is running using FastCGI (PHP-FPM).

## License

Copyright (c) 2021-2022 OWASP ModSecurity Core Rule Set project. All rights reserved.

The OWASP ModSecurity Core Rule Set and its official plugins are distributed
under Apache Software License (ASL) version 2. Please see the enclosed LICENSE
file for full details.
