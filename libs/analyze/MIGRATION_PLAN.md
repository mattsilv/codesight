# CodeSight Analyze Module Migration Plan

## Current Status

The `analyze.sh` command has been refactored into multiple modular components:

1. `libs/analyze/analyze_main.sh` - Main analysis coordinator
2. `libs/analyze/file_collection.sh` - File collection and filtering
3. `libs/analyze/file_processor.sh` - Processing file content
4. `libs/analyze/output_formatter.sh` - Generating formatted output

The original `commands/analyze.sh` now serves as a wrapper that calls the modular implementation.

## Migration Steps

### Phase 1: Refactoring (Completed)
- ✅ Split analyze.sh into modular components
- ✅ Create wrapper to maintain backward compatibility
- ✅ Ensure tests pass with the new structure

### Phase 2: Transition (In Progress)
- ⬜ Update all direct callers to use the modular version
- ⬜ Fix any bugs in the modular implementation
- ⬜ Ensure full feature parity with original implementation
- ⬜ Complete proper error handling in all modules

### Phase 3: Clean-up (Planned)
- ⬜ Remove redundant code in commands/analyze.sh
- ⬜ Simplify commands/analyze.sh to only source and call the modular version
- ⬜ Add comprehensive tests for each module
- ⬜ Update documentation to reflect new structure

## Known Issues

1. The extension stats function in output_formatter.sh needs to be implemented correctly
2. The file paths need to be made relative consistently
3. Error handling needs to be improved in edge cases
4. Some variables are not properly passed between modules
5. Need to prevent redundant execution when called from the wrapper

## Benefits Achieved

- ✅ Improved code organization
- ✅ Better separation of concerns
- ✅ More maintainable code structure
- ✅ Easier to extend individual components
- ✅ Reduced single file complexity