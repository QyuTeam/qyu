# Changelog
- All notable changes to this project will be documented in this file.
- This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

---

[UNRELEASED]: https://github.com/QyuTeam/qyu/compare/v1.1.0...HEAD
## [UNRELEASED]
### Added
-

[v1.1.0]: https://github.com/QyuTeam/qyu/compare/v1.0.2...v1.1.0
## [v1.1.0] March 29, 2018
### Added
- [FEATURE] `Qyu::SplitWorker` to simplify splitting and parallelization of input
- [FEATURE] `Qyu::SyncWorker` can now execute passed blocks if all synced tasks are successful
- [FEATURE] Introduced a `timeout` option for `Qyu::Worker` adding a timeout for each processing task
- [METHOD] `Qyu::Job#workflow`
- [METHOD] `Qyu::Task#descriptor`, `Qyu::Task#workflow_descriptor` and `Qyu::Task#workflow`

### Changed
- [DEPRECATION] `starts_parallel` is now favored over `starts_manually`

[v1.0.2]: https://github.com/QyuTeam/qyu/compare/v1.0.1...v1.0.2
## [v1.0.2] - March 27, 2018
### Added
- Added first `CHANGELOG.md`
- [TESTS] WorkflowDescriptorValidator tests

### Changed
- [BUGFIX] WorkflowDescriptorValidator: Validation was not working due to a missed `&&`
- [BUGFIX] Fix error name `Qyu::Errors::WorkflowDescriptorValidationError`

---

[Template]: https://github.com/QyuTeam/qyu/compare/release-1...release-2
## [Template]
### Added
- Added something

### Changed
- Changed something

### Removed
- Removed something
