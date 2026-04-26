import SwiftUI

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Detail Row View
struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - View Extensions
extension View {
    @available(iOS 16.0, *)
    func emphasizedDetail() -> some View {
        self.fontWeight(.bold)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        let lowercased = status.lowercased()
        // Portfolio statuses
        if lowercased == "owned" || lowercased == "rental" {
            return .green
        } else if lowercased == "for_sale" || lowercased == "for sale" {
            return .orange
        } else if lowercased == "under_contract" || lowercased == "under contract" {
            return .blue
        } else if lowercased == "rehabbing" {
            return .purple
        }
        // General statuses
        if lowercased.contains("active") || lowercased.contains("completed") || lowercased.contains("paid") {
            return .green
        } else if lowercased.contains("pending") || lowercased.contains("processing") {
            return .orange
        } else if lowercased.contains("cancelled") || lowercased.contains("overdue") || lowercased.contains("lost") {
            return .red
        } else if lowercased.contains("new") {
            return .blue
        }
        return .gray
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Project Status Badge
struct ProjectStatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(statusDisplay)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusDisplay: String {
        switch status {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .planning: return .blue
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .purple
        case .cancelled: return .red
        }
    }
}

// Typealias for backward compatibility
typealias DetailRow = DetailRowView

// EmptyStateView is defined in Views/Shared/EmptyStateView.swift
