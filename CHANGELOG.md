## v0.1.18
* Remove nil value items from namespaced options hash prior to merge

## v0.1.16
* Output exception message when reporting error to get full content
* Trap INT to allow nicer user forced exits
* Automatically exit after command block is run
* Print help message and exit non-zero when no command is run

## v0.1.14
* Merge namespaced opts with globals when providing options to allow full config load

## v0.1.12
* Add `Bogo::Cli#config` method that merges `#options` with `#opts`

## v0.1.10
* Pass namespaced configuration through to UI

## v0.1.8
* Always load bogo-config

## v0.1.6
* Remove options when value is nil (fixes merging issues)
* Proxy options to Ui instance when building
* Rescue ScriptError explicitly as it's not within StandardError

## v0.1.4
* Force passed options to Hash type and covert to Smash
* Force passed options keys to snake case
* Include slim error message on unexpected errors when not in debug

## v0.1.2
* Add version restriction to slop
* Allow usage of pre-built Ui instance
* Provide automatic output of hash or string for truthy results
* Add initial spec coverage

## v0.1.0
* Initial release
