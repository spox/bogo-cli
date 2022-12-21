# v0.3.1
* Add context for option parsing (#15)

# v0.3.0
* Remove dependency on slop library (#14)

# v0.2.18
* Include original error message when available

# v0.2.16
* Provide default UI instance and use for error output
* Automatically configure logger on command setup

# v0.2.14
* Prevent unexpected exception when no original is wrapped (#11)

# v0.2.12
* Merge command config to toplevel for UI options

# v0.2.10
* Prevent re-evaluation of configuration files (spox/bogo-config#6)

# v0.2.8
* Load configuration file prior to UI init

# v0.2.6
* Customize error output on configuration file load error (#9)

# v0.2.4
* Prevent defaults from overwriting configuration file values (#8)
* Ensure CLI defaults have precedence over configuration class defaults (#8)

# v0.2.2
* Process CLI values prior to configuration merge (#7)

# v0.2.0
* Include full exception message when debug mode enabled
* Process arguments and check for flags within list

# v0.1.32
* Run previous registered trap if provided
* Allow clean exit or exception raise in main thread on signal

# v0.1.30
* Trap and shutdown on TERM signal (mimic INT behavior)

# v0.1.28
* [hotfix] Resolve default option merging
* Include spec coverage for missed code path

# v0.1.26
* Properly merge user provided options on top of defaults
* Add helper method for determining if option is set as default

# v0.1.24
* [fix] Remove configuration items with `nil` values

# v0.1.22
* Add `Bogo::Cli#config_class` to specify custom `Bogo::Config`
* Always load provided args through config

# v0.1.20
* Bug fix on command initialization when options provided are Hash-like

# v0.1.18
* Remove nil value items from namespaced options hash prior to merge

# v0.1.16
* Output exception message when reporting error to get full content
* Trap INT to allow nicer user forced exits
* Automatically exit after command block is run
* Print help message and exit non-zero when no command is run

# v0.1.14
* Merge namespaced opts with globals when providing options to allow full config load

# v0.1.12
* Add `Bogo::Cli#config` method that merges `#options` with `#opts`

# v0.1.10
* Pass namespaced configuration through to UI

# v0.1.8
* Always load bogo-config

# v0.1.6
* Remove options when value is nil (fixes merging issues)
* Proxy options to Ui instance when building
* Rescue ScriptError explicitly as it's not within StandardError

# v0.1.4
* Force passed options to Hash type and covert to Smash
* Force passed options keys to snake case
* Include slim error message on unexpected errors when not in debug

# v0.1.2
* Add version restriction to slop
* Allow usage of pre-built Ui instance
* Provide automatic output of hash or string for truthy results
* Add initial spec coverage

# v0.1.0
* Initial release
