# Performance Test Report
**Generated:** Mon Sep  8 13:18:04 CEST 2025
**Test Duration:**  minutes
**Test Scenario:** 

## Test Summary

This report summarizes the performance data generated during automated testing.

### Test Configuration
- **iOS Version:** 
- **Device:** Test iPhone
- **App Version:** 1.0+1
- **Environment:** github-actions

### Expected Data in Sentry

Based on the test scenario, the following data should be visible in your Sentry dashboard:

#### Ad Lifecycle Transactions
- **Banner Ads:** Multiple transactions with complete lifecycle tracking
- **Interstitial Ads:** Load → Show → Impression → Dismiss cycles
- **Rewarded Ads:** Load → Show → Video Complete → Dismiss cycles

#### Performance Spans
Each ad interaction should generate the following spans:
- `ad_request` - Initial ad request
- `ad_loading` - Network loading time
- `ad_load_success` or `ad_load_failure` - Load result
- `ad_waiting_for_impression` - Time between load and show
- `ad_show_start` - When ad starts showing
- `ad_impression` - When impression is recorded
- `ad_display_time` - How long ad is displayed
- `ad_click` - User clicks (if any)
- `ad_video_complete` - Video completion (rewarded ads)
- `ad_dismiss` - When ad is dismissed

#### Data Attributes
Each span should include:
- `ad_type`: banner, interstitial, or rewarded
- `ad_unit_id`: The ad unit identifier
- `ad_placement`: naturalBreak, betweenLevels, or achievement
- `battery_level`: Device battery level (may be -1 on simulator)
- `session_duration`: How long the session has been active
- `ad_count`: Number of ads shown in this session

### Test Scenarios Executed

#### All Scenarios
- Continuous data generation over  minutes
- Multiple iterations of each scenario
- Comprehensive performance dataset

**Expected Metrics:**
- High volume of transactions
- Diverse performance patterns
- Realistic usage simulation
- Comprehensive Sentry dataset


### Sentry Dashboard Queries

Use these queries in your Sentry dashboard to analyze the generated data:

#### Performance Queries
```
# Ad lifecycle transactions
transaction:ad.lifecycle

# Banner ad performance
transaction:ad.lifecycle AND ad_type:banner

# Interstitial ad performance  
transaction:ad.lifecycle AND ad_type:interstitial

# Rewarded ad performance
transaction:ad.lifecycle AND ad_type:rewarded

# Failed ad loads
span:ad_load_failure

# Successful ad loads
span:ad_load_success

# Ad impressions
span:ad_impression

# Ad clicks
span:ad_click
```

#### Performance Metrics
```
# Average loading time
avg(span.duration) WHERE span.op:ad_loading

# Fill rate
count(span:ad_load_success) / count(span:ad_request) * 100

# Click-through rate
count(span:ad_click) / count(span:ad_impression) * 100

# Video completion rate
count(span:ad_video_complete) / count(span:ad_show_start) * 100
```

### Next Steps

1. **Check Sentry Dashboard:** Visit your Sentry project to see the generated data
2. **Analyze Performance:** Use the queries above to analyze performance metrics
3. **Monitor Trends:** Set up alerts for performance degradation
4. **Optimize:** Use the data to identify optimization opportunities

### Files Generated

- `app_logs.txt` - Application logs from simulator
- `crash_logs.txt` - Crash logs (if any)
- `performance_report_2025-09-08_13-18-04.md` - This report

