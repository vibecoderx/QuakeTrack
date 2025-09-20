//
//  AboutView.swift
//  QuakeTrack
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center, spacing: 20) {
                        Image("QuakeTrack_seismic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(radius: 5)
                        
                        Text("QuakeTrack")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(AppInfoHelper.versionInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // NEW: Display the Git Commit SHA
                        Text("Commit: \(AppInfoHelper.gitCommitSHA)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section(header: Text("Data Source")) {
                    Text("This app uses earthquake data provided by the U.S. Geological Survey (USGS) Earthquake Hazards Program.")
                    if let url = URL(string: "https://earthquake.usgs.gov") {
                        Link("Visit USGS Website", destination: url)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

