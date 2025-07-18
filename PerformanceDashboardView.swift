//
//  PerformanceDashboardView.swift
//  MobileInAppAdvertisement
//
//  Created by Angelo de Voer on 03/06/2025.
//

import SwiftUI

struct PerformanceDashboardView: View {
    @ObservedObject private var performanceTracker = AdPerformanceTracker.shared
    @State private var showingDetailedMetrics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Key Metrics Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        metricCard(title: "Impressions", value: "\(performanceTracker.adMetrics.impressionCount)", color: .blue)
                        metricCard(title: "Fill Rate", value: String(format: "%.1f%%", performanceTracker.adMetrics.fillRate), color: .green)
                        metricCard(title: "CTR", value: String(format: "%.2f%%", performanceTracker.adMetrics.clickThroughRate), color: .orange)
                        metricCard(title: "Avg Latency", value: String(format: "%.2fs", performanceTracker.adMetrics.averageAdLatency), color: .purple)
                    }
                    
                    // Detailed Metrics
                    detailedMetricsSection
                    
                    // Performance Alerts
                    performanceAlertsSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        showingDetailedMetrics = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailedMetrics) {
            DetailedMetricsView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("📊 Ad Performance Monitor")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Real-time advertisement metrics and performance tracking")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var detailedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 Detailed Metrics")
                .font(.headline)
            
            VStack(spacing: 12) {
                metricRow(title: "Ad Requests", value: "\(performanceTracker.adMetrics.adRequestCount)")
                metricRow(title: "Load Success", value: "\(performanceTracker.adMetrics.adLoadSuccessCount)")
                metricRow(title: "Load Failures", value: "\(performanceTracker.adMetrics.adLoadFailureCount)")
                metricRow(title: "Clicks", value: "\(performanceTracker.adMetrics.clickCount)")
                metricRow(title: "Rewarded Completions", value: "\(performanceTracker.adMetrics.rewardedVideoCompletions)")
                metricRow(title: "Session Frequency", value: "\(performanceTracker.adMetrics.adFrequencyPerSession)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
    
    private var performanceAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Performance Alerts")
                .font(.headline)
            
            VStack(spacing: 8) {
                if performanceTracker.adMetrics.fillRate < 80 {
                    alertRow(message: "Low fill rate detected", severity: .warning)
                }
                
                if performanceTracker.adMetrics.averageAdLatency > 3.0 {
                    alertRow(message: "High ad latency detected", severity: .error)
                }
                
                if performanceTracker.adMetrics.clickThroughRate < 0.5 {
                    alertRow(message: "Low CTR detected", severity: .warning)
                }
                
                if performanceTracker.adMetrics.adFrequencyPerSession > 3 {
                    alertRow(message: "Excessive ad frequency", severity: .error)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func alertRow(message: String, severity: AlertSeverity) -> some View {
        HStack {
            Image(systemName: severity.icon)
                .foregroundColor(severity.color)
            
            Text(message)
                .font(.caption)
                .foregroundColor(severity.color)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(severity.color.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Start New Session") {
                performanceTracker.startSession()
            }
            .buttonStyle(.borderedProminent)
            
            Button("End Session") {
                performanceTracker.endSession()
            }
            .buttonStyle(.bordered)
            
            Button("Export Metrics") {
                exportMetrics()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func exportMetrics() {
        // Export metrics to Sentry or local storage
        let metrics = performanceTracker.adMetrics
        print("📤 Exporting metrics to Sentry...")
        
        // Create a comprehensive Sentry event with all metrics
        let event = Event()
        event.message = SentryMessage(formatted: "Ad Performance Metrics Export")
        event.setTag(value: String(metrics.impressionCount), key: "total_impressions")
        event.setTag(value: String(metrics.clickCount), key: "total_clicks")
        event.setTag(value: String(format: "%.2f", metrics.clickThroughRate), key: "ctr_percentage")
        event.setTag(value: String(format: "%.2f", metrics.fillRate), key: "fill_rate_percentage")
        event.setTag(value: String(format: "%.2f", metrics.averageAdLatency), key: "avg_latency_seconds")
        event.setTag(value: String(metrics.rewardedVideoCompletions), key: "rewarded_completions")
        event.setTag(value: String(format: "%.2f", metrics.rewardedVideoCompletionRate), key: "completion_rate_percentage")
        
        SentrySDK.capture(event: event)
    }
}

struct DetailedMetricsView: View {
    @ObservedObject private var performanceTracker = AdPerformanceTracker.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Latency Distribution
                    latencyDistributionSection
                    
                    // Ad Type Breakdown
                    adTypeBreakdownSection
                    
                    // Performance Trends
                    performanceTrendsSection
                }
                .padding()
            }
            .navigationTitle("Detailed Metrics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var latencyDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️ Ad Latency Distribution")
                .font(.headline)
            
            VStack(spacing: 8) {
                latencyBar(label: "< 1s", count: performanceTracker.adMetrics.adLatency.filter { $0 < 1.0 }.count, total: performanceTracker.adMetrics.adLatency.count)
                latencyBar(label: "1-2s", count: performanceTracker.adMetrics.adLatency.filter { $0 >= 1.0 && $0 < 2.0 }.count, total: performanceTracker.adMetrics.adLatency.count)
                latencyBar(label: "2-3s", count: performanceTracker.adMetrics.adLatency.filter { $0 >= 2.0 && $0 < 3.0 }.count, total: performanceTracker.adMetrics.adLatency.count)
                latencyBar(label: "> 3s", count: performanceTracker.adMetrics.adLatency.filter { $0 >= 3.0 }.count, total: performanceTracker.adMetrics.adLatency.count)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func latencyBar(label: String, count: Int, total: Int) -> some View {
        HStack {
            Text(label)
                .frame(width: 40, alignment: .leading)
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: total > 0 ? geometry.size.width * CGFloat(count) / CGFloat(total) : 0)
            }
            .frame(height: 20)
            .background(Color(.systemGray5))
            .cornerRadius(4)
            
            Text("\(count)")
                .font(.caption)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    private var adTypeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Ad Type Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                adTypeRow(type: "Banner", count: performanceTracker.adMetrics.impressionCount / 3) // Simulated breakdown
                adTypeRow(type: "Interstitial", count: performanceTracker.adMetrics.impressionCount / 3)
                adTypeRow(type: "Rewarded", count: performanceTracker.adMetrics.impressionCount / 3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func adTypeRow(type: String, count: Int) -> some View {
        HStack {
            Text(type)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
        }
    }
    
    private var performanceTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📈 Performance Trends")
                .font(.headline)
            
            VStack(spacing: 8) {
                trendRow(label: "Fill Rate Trend", value: performanceTracker.adMetrics.fillRate, target: 90.0)
                trendRow(label: "CTR Trend", value: performanceTracker.adMetrics.clickThroughRate, target: 2.0)
                trendRow(label: "Latency Trend", value: performanceTracker.adMetrics.averageAdLatency, target: 2.0, lowerIsBetter: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func trendRow(label: String, value: Double, target: Double, lowerIsBetter: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            let isGood = lowerIsBetter ? value <= target : value >= target
            Image(systemName: isGood ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(isGood ? .green : .red)
            
            Text(String(format: "%.1f", value))
                .fontWeight(.semibold)
        }
    }
}

enum AlertSeverity {
    case warning
    case error
    
    var icon: String {
        switch self {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

#Preview {
    PerformanceDashboardView()
} 