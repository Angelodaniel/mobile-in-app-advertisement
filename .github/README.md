# GitHub Actions Data Simulation

This directory contains GitHub Actions workflows for automated data simulation and testing.

## Workflows

### 1. Data Simulation ()
- **Schedule:** Every 6 hours
- **Purpose:** Generates performance data using iOS Simulator
- **Features:**
  - Automated UI interactions
  - Multiple test scenarios
  - Performance data generation
  - Sentry integration

### 2. UI Tests ()
- **Schedule:** Every 4 hours
- **Purpose:** Comprehensive UI testing and validation
- **Features:**
  - Automated UI tests
  - Performance testing
  - Error handling validation
  - Continuous data generation

## Test Scenarios

### Working Ads
- Uses Google's test ad unit IDs
- All ads load successfully
- Complete lifecycle tracking
- No error spans

### Failing Ads
- Uses invalid ad unit IDs
- All ads fail to load
- Error tracking spans
- No successful impressions

### Mixed Scenario
- Alternates between working and failing ads
- Realistic user behavior
- Mixed performance patterns

### Performance Tests
- Ad loading performance
- Banner ad performance
- Timing measurements
- Optimization insights

## Manual Triggering

You can manually trigger workflows with different parameters:

```bash
# Trigger data simulation
gh workflow run data-simulation.yml

# Trigger UI tests
gh workflow run ui-tests.yml

# Trigger with specific parameters
gh workflow run data-simulation.yml -f test_scenario=working_ads
gh workflow run ui-tests.yml -f test_type=performance
```

## Monitoring

### Sentry Dashboard
- Check your Sentry project for generated performance data
- Use the provided queries to analyze metrics
- Set up alerts for performance degradation

### GitHub Actions
- View workflow runs in the Actions tab
- Download test results and reports
- Monitor test execution logs

## Configuration

### Sentry Setup
1. Update `sentry.properties` with your Sentry configuration
2. Ensure your Sentry project is properly configured
3. Verify DSN and project settings

### Test Configuration
- Modify test scenarios in workflow files
- Adjust test duration and frequency
- Customize test parameters as needed

## Troubleshooting

### Common Issues
1. **Simulator not starting:** Check Xcode and iOS Simulator installation
2. **App not installing:** Verify build configuration and simulator setup
3. **Tests failing:** Check UI test implementation and app state
4. **Sentry data not appearing:** Verify Sentry configuration and network connectivity

### Debug Steps
1. Check workflow logs for detailed error messages
2. Verify simulator and app installation
3. Test locally before running in GitHub Actions
4. Check Sentry project configuration

## Files

- `data-simulation.yml` - Main data simulation workflow
- `ui-tests.yml` - UI testing workflow
- `scripts/` - Supporting scripts for data generation
- `test-results/` - Generated test results and reports
- `performance-reports/` - Performance analysis reports
- `analysis-reports/` - Test analysis and insights

