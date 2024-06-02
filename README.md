# OWASP CRS - Body Decompress Plugin

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

 * ModSecurity v2 compiled with Lua support (ModSecurity v3 is currently unsupported)
 * lua-zlib library

## How to determine whether you have Lua support in ModSecurity

Most modern distro packages come with Lua support compiled in. If you are unsure, or if you get odd error messages (e.g. `EOL found`) chances are you are unlucky. To be really sure look for ModSecurity announce Lua support when launching your web server:

```
... ModSecurity for Apache/2.9.5 (http://www.modsecurity.org/) configured.
... ModSecurity: APR compiled version="1.7.0"; loaded version="1.7.0"
... ModSecurity: PCRE compiled version="8.39 "; loaded version="8.39 2016-06-14"
... ModSecurity: LUA compiled version="Lua 5.3"
...
```

If this line is missing, then you are probably stuck without Lua. Check out the documentation at [coreruleset.org](https://coreruleset.org/docs) to learn how to get Lua support for your installation.

## lua-zlib library installation

lua-zlib library should be part of your linux distribution. Here is an example
of installation on Debian linux:  
`apt install lua-zlib`

## Plugin installation

For full and up to date instructions for the different available plugin
installation methods, refer to [How to Install a Plugin](https://coreruleset.org/docs/concepts/plugins/#how-to-install-a-plugin)
in the official CRS documentation.

## Configuration

All settings can be done in file `plugins/body-decompress-config.conf`.

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

Copyright (c) 2021-2022 OWASP CRS project. All rights reserved.

The OWASP CRS and its official plugins are distributed
under Apache Software License (ASL) version 2. Please see the enclosed LICENSE
file for full details.
