//
//  SearchView.swift
//  QuakeTrack
//

import SwiftUI

struct SearchView: View {
    enum SearchMode: String, CaseIterable, Identifiable {
        case byYear = "By Year"
        case byDate = "By Date"
        var id: Self { self }
    }
    
    @State private var searchMode: SearchMode = .byYear
    
    // State for the year search
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    let years = Array((1901...Calendar.current.component(.year, from: Date())).reversed())
    
    // State for the date search
    @State private var selectedDate: Date = Date()
    private var dateRange: ClosedRange<Date> {
        let minDate = Calendar.current.date(from: DateComponents(year: 1901, month: 1, day: 1))!
        let maxDate = Date() // Today
        return minDate...maxDate
    }
    
    // State to control the presentation of the "About" sheet
    @State private var isAboutSheetPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Search Mode", selection: $searchMode) {
                        ForEach(SearchMode.allCases) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if searchMode == .byYear {
                    Section(header: Text("Select a Year")) {
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Section(header: Text("Select a Date")) {
                        DatePicker("Date", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                
                Section {
                    let destination = SearchResultsView(
                        searchMode: searchMode == .byYear ? .byYear : .byDate,
                        selectedYear: searchMode == .byYear ? selectedYear : nil,
                        selectedDate: searchMode == .byDate ? selectedDate : nil
                    )
                    
                    NavigationLink(destination: destination) {
                        HStack {
                            Spacer()
                            Text("Search")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Search Earthquakes")
            // Add a toolbar to hold the new "Info" button
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isAboutSheetPresented = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            // Add a sheet modifier to present the AboutView
            .sheet(isPresented: $isAboutSheetPresented) {
                AboutView()
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

