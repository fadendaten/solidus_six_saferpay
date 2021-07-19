# Changelog

## 0.6.0
Using the extension generator from `solidus_dev_support`. This version fixes solidus to 2.10 to prepare for the 2.11 and 3 migrations.

#### Breaking Changes

* `SolidusSixSaferpay::Configuration.error_handlers` is no longer exposed as a class method, please migrate to `SolidusSixSaferpay.config.error_handlers`

